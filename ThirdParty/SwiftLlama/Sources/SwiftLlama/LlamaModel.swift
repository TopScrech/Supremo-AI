import Foundation
import llama

class LlamaModel {
    private let model: Model
    private let vocab: OpaquePointer
    private let configuration: Configuration
    private let context: OpaquePointer
    private let sampler: UnsafeMutablePointer<llama_sampler>
    private var batch: Batch
    private var tokens: [Token]
    private var currentTokenPosition: Int32 = 0
    private var generatedTokenCount: Int32 = 0
    private var ended = false

    var shouldContinue: Bool {
        generatedTokenCount < configuration.maxTokenCount && !ended
    }

    init(path: String, configuration: Configuration = .init()) throws {
        self.configuration = configuration
        llama_backend_init()
        llama_numa_init(GGML_NUMA_STRATEGY_DISABLED)

        var model_params = llama_model_default_params()
        if !configuration.useMetal {
            model_params.n_gpu_layers = 0
        }
        #if targetEnvironment(simulator)
            model_params.n_gpu_layers = 0
        #endif

        guard let model = llama_load_model_from_file(path, model_params) else {
            throw SwiftLlamaError.others("Cannot load model at path \(path)")
        }
        self.model = model
        guard let vocab = llama_model_get_vocab(model) else {
            throw SwiftLlamaError.others("Cannot load model vocabulary")
        }
        self.vocab = vocab

        guard let context = llama_new_context_with_model(model, configuration.contextParameters) else {
            throw SwiftLlamaError.others("Cannot load model context")
        }
        self.context = context

        self.tokens = []
        self.batch = llama_batch_init(Int32(configuration.batchSize * Configuration.historySize * 2), 0, 1)

        self.sampler = llama_sampler_chain_init(llama_sampler_chain_default_params())
        llama_sampler_chain_add(sampler, llama_sampler_init_top_k(Int32(configuration.topK)))
        llama_sampler_chain_add(sampler, llama_sampler_init_top_p(configuration.topP, 1))
        llama_sampler_chain_add(sampler, llama_sampler_init_temp(configuration.temperature))
        llama_sampler_chain_add(sampler, llama_sampler_init_dist(UInt32(configuration.seed)))

        try checkContextLength(context: context, model: model)
    }

    private func checkContextLength(context: Context, model: Model) throws {
        let n_ctx = llama_n_ctx(context)
        let n_ctx_train = llama_n_ctx_train(model)
        if n_ctx > n_ctx_train {
            throw SwiftLlamaError.others("Model was trained on \(n_ctx_train) context but tokens \(n_ctx) specified")
        }
    }

    func start(for prompt: Prompt) throws {
        clear()
        ended = false
        currentTokenPosition = 0
        generatedTokenCount = 0
        llama_sampler_reset(sampler)
        print("SwiftLlama Gemma4: tokenizing prompt characters=\(prompt.prompt.count)")
        tokens = tokenize(text: prompt.prompt, addBos: true)
        print("SwiftLlama Gemma4: tokenized prompt tokens=\(tokens.count)")
        guard !tokens.isEmpty else {
            throw SwiftLlamaError.others("Prompt tokenization returned no tokens")
        }
        let contextLength = Int(llama_n_ctx(context))
        guard tokens.count < contextLength else {
            throw SwiftLlamaError.others("Prompt has \(tokens.count) tokens but the context supports \(contextLength)")
        }

        print("SwiftLlama Gemma4: starting prompt decode tokens=\(tokens.count) batchSize=\(configuration.batchSize)")
        try decodePromptChunks()
        print("SwiftLlama Gemma4: finished prompt decode")
        currentTokenPosition = Int32(tokens.count)
    }

    private func decodePromptChunks() throws {
        for chunkStart in stride(from: 0, to: tokens.count, by: configuration.batchSize) {
            let chunkEnd = min(chunkStart + configuration.batchSize, tokens.count)
            let isLastChunk = chunkEnd == tokens.count

            batch.clear()
            for index in chunkStart..<chunkEnd {
                batch.add(token: tokens[index], position: Int32(index), seqIDs: [0], logit: false)
            }
            if isLastChunk {
                batch.logits[Int(batch.n_tokens) - 1] = 1
            }

            print("SwiftLlama Gemma4: decoding prompt chunk tokens=\(batch.n_tokens)")
            if llama_decode(context, batch) != 0 {
                throw SwiftLlamaError.decodeError
            }
        }
    }

    func `continue`() throws -> String {
        if generatedTokenCount == 0 {
            print("SwiftLlama Gemma4: sampling first response token")
        }
        let newToken = llama_sampler_sample(sampler, context, batch.n_tokens - 1)

        if llama_vocab_is_eog(vocab, newToken) || currentTokenPosition >= Int32(llama_n_ctx(context)) {
            ended = true
            return ""
        }

        let piece = tokenToString(token: newToken)

        batch.clear()
        batch.add(token: newToken, position: currentTokenPosition, seqIDs: [0], logit: true)
        currentTokenPosition += 1
        generatedTokenCount += 1

        if generatedTokenCount == 1 {
            print("SwiftLlama Gemma4: decoding first response token")
        }
        if llama_decode(context, batch) != 0 {
            throw SwiftLlamaError.decodeError
        }
        if generatedTokenCount == 1 {
            print("SwiftLlama Gemma4: decoded first response token")
        }
        return piece
    }

    // MARK: - Helpers

    /// Convert a sampled token to a Swift String (valid UTF-8, no interleaved \0 bytes).
    private func tokenToString(token: llama_token) -> String {
        var cap: Int32 = 32
        var buf = [CChar](repeating: 0, count: Int(cap))

        // First attempt
        var written = buf.withUnsafeMutableBufferPointer { p -> Int32 in
            guard let base = p.baseAddress else { return 0 }
            // Use the signature your llama module exposes (this matches your previous use: 6 args)
            return llama_token_to_piece(vocab, token, base, cap, 0, false)
        }

        // If negative, allocate required size and retry
        if written < 0 {
            cap = -written
            buf = [CChar](repeating: 0, count: Int(cap))
            written = buf.withUnsafeMutableBufferPointer { p -> Int32 in
                guard let base = p.baseAddress else { return 0 }
                return llama_token_to_piece(vocab, token, base, cap, 0, false)
            }
        }

        let count = Int(max(0, written))
        if count == 0 { return "" }

        // Decode exact byte count (no trailing NUL included)
        let bytes: [UInt8] = buf.prefix(count).map { UInt8(bitPattern: $0) }
        return String(decoding: bytes, as: UTF8.self)
    }

    private func tokenize(text: String, addBos: Bool) -> [Token] {
        let utf8Count = text.utf8.count
        let n_tokens = utf8Count + (addBos ? 1 : 0) + 1

        return Array(unsafeUninitializedCapacity: n_tokens) { buffer, initializedCount in
            let tokenCount = Int(
                llama_tokenize(vocab, text, Int32(utf8Count), buffer.baseAddress, Int32(n_tokens), addBos, true)
            )
            initializedCount = max(0, min(tokenCount, n_tokens))
        }
    }

    func clear() {
        ended = false
        currentTokenPosition = 0
        generatedTokenCount = 0
        tokens.removeAll()
        llama_memory_clear(llama_get_memory(context), true)
    }

    deinit {
        llama_batch_free(batch)
        llama_sampler_free(sampler)
        llama_free(context)
        llama_free_model(model)
    }
}
