import Foundation
import Plot
import Publish
import SplashPublishPlugin

struct JimmyLee: Website {
    enum SectionID: String, WebsiteSectionID {
        case posts
    }

    struct ItemMetadata: WebsiteItemMetadata {
        // Add any site-specific metadata that you want to use here.
    }

    var url = URL(string: "http://localhost:8000")!
    var name = "李昇輯"
    var description = "iOS Developer"
    var language: Language { .twi }
    var imagePath: Path? { nil }
    let favicon: Favicon? = .init(path: "profile.jpg", type: "image/jpg")

    // Contact
    let contacts: [Contact] = [
        .init(icon: "/map.png", href: "https://goo.gl/maps/P54AL2dvAHbti2aw5", name: "Taipei, Taiwan"),
        .init(icon: "/github.png", href: "https://github.com/Jimmy-Lee", name: "Jimmy-Lee"),
        .init(icon: "/linkedin.png", href: "https://www.linkedin.com/in/%E6%98%87%E8%BC%AF-%E6%9D%8E-8a5340112/", name: "李昇輯"),
        .init(icon: "/twitter.png", href: "https://twitter.com/jimmy_prime", name: "@jimmy_prime"),
        .init(icon: "/email.png", href: "mailto:jimmylevelup@gmail.com", name: "jimmylevelup@gmail.com")
    ]
}

extension JimmyLee {
    struct Contact {
        let icon: String
        let href: String
        let name: String
    }
}

try JimmyLee().publish(using: [
    .installPlugin(.splash(withClassPrefix: "")),
    .addMarkdownFiles(),
    .generateHTML(withTheme: .JimmyLee)
])

// Command line build
// publish generate; cp -R Output/ ../jimmy-lee.github.io/
