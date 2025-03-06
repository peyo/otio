enum InsightSymbol {
    static func sfSymbol(for emojiName: String) -> String {
        switch emojiName {
        case "emotional-pattern":
            return "waveform.path"
        case "encouraging-tip":
            return "sparkles"
        case "self-reflection":
            return "person.fill.questionmark"
        case "zen":
            return "leaf.fill"
        default:
            return "questionmark"
        }
    }
}