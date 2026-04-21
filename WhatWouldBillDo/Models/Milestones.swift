import Foundation

struct Milestone: Hashable {
    let days: Int
    let label: String
    let message: String
}

enum Milestones {
    static let all: [Milestone] = [
        Milestone(days: 1,    label: "Your first day",
                  message: "One day. That was my first, too. Keep coming back."),
        Milestone(days: 7,    label: "One week",
                  message: "A week without a drink. You've done something most cannot."),
        Milestone(days: 30,   label: "Thirty days",
                  message: "Thirty days. You've broken something that was breaking you."),
        Milestone(days: 60,   label: "Two months",
                  message: "Two months. The habit is loosening its grip."),
        Milestone(days: 90,   label: "Ninety days",
                  message: "Ninety days. You are becoming who you were meant to be."),
        Milestone(days: 180,  label: "Six months",
                  message: "Six months. You are not the same person who started."),
        Milestone(days: 365,  label: "One year",
                  message: "One year. You have given yourself a life."),
        Milestone(days: 730,  label: "Two years",
                  message: "Two years. You are free."),
        Milestone(days: 1825, label: "Five years",
                  message: "Five years. Your story saves others now.")
    ]

    static func current(for days: Int) -> Milestone? {
        all.first(where: { $0.days == days })
    }

    static func next(after days: Int) -> Milestone? {
        all.first(where: { $0.days > days })
    }
}
