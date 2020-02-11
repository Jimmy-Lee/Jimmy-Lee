import Foundation
import Plot
import Publish

extension Theme where Site == JimmyLee {
    static var JimmyLee: Self {
        Theme(
            htmlFactory: JimmyLeeHTMLFactory(),
            resourcePaths: [
                "Resources/styles.css",
                "Resources/syntax.css",
                "Resources/email.png",
                "Resources/github.png",
                "Resources/linkedin.png",
                "Resources/map.png",
                "Resources/profile.jpg",
                "Resources/twitter.png"
            ]
        )
    }
}

private struct JimmyLeeHTMLFactory: HTMLFactory {
    func makeIndexHTML(for index: Index, context: PublishingContext<JimmyLee>) throws -> HTML {
        content(
            location: index,
            site: context.site,
            postList(
                for: context.allItems(sortedBy: \.date, order: .descending),
                on: context.site
            )
        )
    }

    func makeSectionHTML(for section: Section<JimmyLee>, context: PublishingContext<JimmyLee>) throws -> HTML {
        HTML()
    }

    func makeItemHTML(for item: Item<JimmyLee>, context: PublishingContext<JimmyLee>) throws -> HTML {
        content(
            location: item,
            site: context.site,
            .h1(.text(item.title)),
            tagList(for: item, on: context.site),
            .span(.class("date"), .text(string(from: item.date))),
            .article(.contentBody(item.content.body))
        )
    }

    func makePageHTML(for page: Page, context: PublishingContext<JimmyLee>) throws -> HTML {
        HTML()
    }

    func makeTagListHTML(for page: TagListPage, context: PublishingContext<JimmyLee>) throws -> HTML? {
        content(
            location: page,
            site: context.site,
            .h1("All tags"),
            .ul(
                .class("tags"),
                .forEach(page.tags.sorted()) { tag in
                    .li(
                        .class("tag"),
                        .a(
                            .href(context.site.path(for: tag)),
                            .text(tag.string)
                        )
                    )
                }
            )
        )
    }

    func makeTagDetailsHTML(for page: TagDetailsPage, context: PublishingContext<JimmyLee>) throws -> HTML? {
        content(
            location: page,
            site: context.site,
            .h1("Tagged with ", .span(.class("tag"), .text(page.tag.string))),
            .a(.class("browse-all"), .href(context.site.tagListPath), .text("Browse all tags")),
            postList(
                for: context.items(taggedWith: page.tag, sortedBy: \.date, order: .descending),
                on: context.site
            )
        )
    }
}

extension JimmyLeeHTMLFactory {
    func content(location: Location, site: JimmyLee, _ content: Node<HTML.BodyContext>...) -> HTML {
        HTML(
            .lang(site.language),
            .head(
                for: location,
                on: site,
                stylesheetPaths: [
                    "https://unpkg.com/purecss@1.0.1/build/base-min.css",
                    "https://unpkg.com/purecss@1.0.1/build/grids-responsive-min.css",
                    "/styles.css",
                    "/syntax.css"
                ]
            ),
            .body(
                .div(
                    .class("pure-g"),
                    sideBar(site),
                    .element(named: "div", nodes: [.class("content pure-u-1 pure-u-md-3-5")] + content),
                    footer(for: site)
                )
            )
        )
    }

    func sideBar(_ site: JimmyLee) -> Node<HTML.BodyContext> {
        .div(
            .class("sidebar pure-u-1 pure-u-md-1-5"),
            .img(.class("profile"), .src("/profile.jpg")),
            .h1(.a(.class("theme"), .href("/"), .text(site.name))),
            .h3(.text(site.description)),
            .forEach(site.contacts) { contact in
                .div(
                    .class("contact"),
                    .img(.class("icon"), .src(contact.icon)),
                    .span(.a(.href(contact.href), .text(contact.name)))
                )
            }
        )
    }

    func postList(for items: [Item<JimmyLee>], on site: JimmyLee) -> Node<HTML.BodyContext> {
        .forEach(items) { item in
            .article(
                .h1(.a(.class("theme"), .href(item.path), .text(item.title))),
                tagList(for: item, on: site),
                .span(.class("date"), .text(string(from: item.date))),
                .p(.text(item.description))
            )
        }
    }

    func footer(for site: JimmyLee) -> Node<HTML.BodyContext> {
        .footer(
            .p(
                .text("Generated using "),
                .a(
                    .text("Publish"),
                    .href("https://github.com/johnsundell/publish")
                )
            ),
            .p(.a(
                .text("RSS feed"),
                .href("/feed.rss")
            ))
        )
    }

    func tagList(for item: Item<JimmyLee>, on site: JimmyLee) -> Node<HTML.BodyContext> {
        .forEach(item.tags) { tag in
            .tag(
                .a(
                    .href(site.path(for: tag)),
                    .text(tag.string)
                )
            )
        }
    }

    func string(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        return dateFormatter.string(from: date)
    }
}

extension Node where Context: HTML.BodyContext {
    /// Add an `<tag>` HTML element within the current context.
    /// - parameter nodes: The element's attributes and child elements.
    static func tag(_ nodes: Node<HTML.AnchorContext>...) -> Node {
        .element(named: "tag", nodes: nodes)
    }
}
