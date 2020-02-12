---
date: 2020-02-12 17:30
title: Heterogeneous Array Decoding (TW)
description: Heterogeneous array decoding.
tags: decodable, generics
---

## Heterogeneous array 是什麼

假設我們在做一個聊天軟體，有一支 api 會回傳所有 user，response 長這樣：

``` JSON
{
    "users": [
        {
            "id": 1,
            "type": "human",
            "name": "jimmylee",
            "nickname": "升級"
        },
        {
            "id": 2,
            "type": "bot",
            "purpose": "git hook"
        }
    ]
}
```

我們根據 response 建立 User model：

``` Swift
class User: Decodable {
    let id: Int
}

class Human: User {
    let name: String
    let nickname: String

    // omit Decodable implementation for simplicity
}

class Bot: User {
    let purpose: String

    // omit Decodable implementation for simplicity
}
```

我們的目標是把上面的 json decode 成 `[User]`，裡面應該有 `Human`, `Bot`, `User` instance。這個 `[User]` 就叫做 heterogeneous array。

## Decoding

現在我們就來想一下要怎麼 decode，先寫一個簡單的做法：

``` Swift
protocol Request {
    associatedtype Response
}

struct UserListRequst: Request {
    typealias Response = [User]
}

func send<R: Request>(_ request: R) -> AnyPublisher<R.Response, Error> {
    session.dataTaskPublisher(for: buildURLRequest(from: request))
        .map { $0.data }
        .decode(type: R.Response.self, decoder: JSONDecoder())
        .eraseToAnyPublisher()
}

let userListPublisher = send(UserListRequst())
```

我們指定 `UserListRequest` 的 `Response` 是 `[User]`，compile 沒有問題，可惜的是這個做法結果是錯的，decode 出來的 `[User]` 所有 instance 都是 `User`，沒有 `Human` 或 `Bot`，這篇文章就是要處理這個問題。

在嘗試用程式解決問題之前，先想一下人類是怎麼 *decode* 的。我們知道 array 裡一個 object 會對應到一個 `User`，實際上是哪一個 subclass 要再進到 object 裡面，找到 key "type" 的 value，再回頭把整個 object decode 成對應的 `User`。

整理一下需要實作的東西：

1. 需要有 `string` -> `User` 的對應表
2. 要有方法可以先找到 type，再回頭 decode 整個 object

這時候需要自己實作 `init(from decoder:)` 了。

``` Swift
struct UserListRequest: Request {
    struct Response: Decodable {
        let list: [User]
    }

    // 1
    private enum CodingKeys: String, CodingKey {
        case users
        case type
    }

    // 2
    private enum UserFamily: String, Decodable {
        case human
        case bot

        var type: User.Type {
            switch self {
            case .human:
                return Human.self
            case .bot:
                return Bot.self
            }
        }
    }

    init(from decoder: Decoder) throws { ... }
}
```

1. 先定義會用到的 CodingKey
2. 定義一種 type safe 的方式把 `string` 轉成 `User`

接下來是 `init(from decoder: Decoder)` 裡面的實作

``` Swift
init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    var typeContainer = try container.nestedUnkeyedContainer(forKey: .users)
    var list: [User] = []

    var listContainer = typeContainer // 1
    while !listContainer.isAtEnd {
        let user = try typeContainer.nestedContainer(keyedBy: CodingKeys.self)
        if let type = try? user.decode(UserFamily.self, forKey: .type) {
            list.append(try listContainer.decode(type.type))
        } else {
            list.append(try listContainer.decode(User.self))
        }
    }

    self.list = list
}
```

1. 這裡為什麼要這樣寫，就我的理解是因為 `decoder` 很像 file pointer，只能一直往前。所以需要一個進去找到 type，一個留在 object 的起點。

## Improvements

OK，到這邊其實就完成了，但這個實作有一些缺點：

1. 每個 response 的 key 不同，也可能沒有 key
2. 每個 response 的 type family 不同
3. init(from: Decoder) 每次都要重寫

### TypeKey

在 response 裡面，這個 instance 是什麼 type 的 key。目前所有用途都用 “type”，所以直接定義一個 global enum，未來有型別不使用 “type” 可以再修改。

``` Swift
enum TypeKey: CodingKey {
    case type
}
```

### TypeFamily

把 `string` 轉成 `type` 這部分變成介面。

``` Swift
protocol TypeFamily: Decodable {
    associatedtype Member: Decodable
    var type: Member.Type { get }
}
```

原本 `UserFamily` 實作 Decodable，改成 `TypeFamily` 就可以了。

``` Swift
private enum UserFamily: String, TypeFamily {
    case human
    case bot

    var type: User.Type {
        switch self {
        case .human:
            return Human.self
        case .bot:
            return Bot.self
        }
    }
}
```

### KeyedListKey

Response array 外面可能還有一層 key

``` JSON
# keyed response
{
    "user": []
}

# unkeyed response
[]
```

我們定義一下 Keyed 的介面

``` Swift
protocol KeyedListKey: CodingKey {
    static var key: Self { get }
}

enum UserListKey: KeyedListKey {
    case users
    
    static let key = Self.users
}
```

### 組裝在一起

有了 TypeKey, TypeFamily, KeyedListKey 之後，我們可以把 `init(from decoder: Decoder)` 裡面的東西全部拆出來。

``` Swift
struct KeyedHeterogeneousList<Family: TypeFamily, Key: KeyedListKey>: Decodable {
    let list: [Family.Member]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        var typeContainer = try container.nestedUnkeyedContainer(forKey: Key.key)
        var list: [Family.Member] = []

        var listContainer = typeContainer
        while !listContainer.isAtEnd {
            let instance = try typeContainer.nestedContainer(keyedBy: TypeKey.self)
            if let type = try? instance.decode(Family.self, forKey: .type) {
                list.append(try listContainer.decode(type.type))
            } else {
                list.append(try listContainer.decode(Family.Member.self))
            }
        }

        self.list = list
    }
}
```

和原本 `UserListRequest` 裡面實作的結構一樣，只是用 generic 帶換掉和 `User` 綁在一起的部分。有了 `KeyedHeterogeneousList` 之後，可以把 `UserListRequest` 改寫成：

``` Swift
struct UserListRequest: Request {
    typealias Response: KeyedHeterogeneousList<UserFamily, UserListKey>
}
```

## Reference

一開始的想法是從[這篇文章](https://medium.com/@kewindannerfjordremeczki/swift-4-0-decodable-heterogeneous-collections-ecc0e6b468cf)來的，這裡提供了怎麼先拿到 type 再 decode 整個 object 的方法。我基於這裡的 code 再用 generic 改進。

完整的 code 可以參考我的 [gist](https://gist.github.com/Jimmy-Lee/c66a613403f912d35c2d226ff1b9c16f)，裡面有完整的 Keyed, Unkeyed 版本和 unit test。
