---
date: 2020-02-07 12:00
title: Heterogeneous Array Decoding
description: Heterogeneous array decoding.
---

Suppose we are building a chat app, we have an api that returns all users, the response is:

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

We can model our User types as classes using inheritence, like this:

``` Swift
class User: Decodable {
    let id: Int
}

class Human: User {
    let name: String
    let nickname: String

    // omit Decodable implementation
}

class Bot: User {
    let purpose: String

    // omit Decodable implementation
}
```

Now we want to decode the response into an `User` array, which contains instances of `Human`, `Bot` and `User`. This `User` array `[User]` is called as a heterogeneous array.

Let's try to decode the response into an `User` array. We come up with a intuitive solution:

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

However, this does not work. Every instance in the `User` array would be `User`, and no `Human` nor `Bot`. In this post, we are going to solve this problem.

Before we try to write code, we step back to see how human *decode* the response. First we recognize this is a user array, should contains instances of `Human` or `Bot`. How do we determine the type of an object? We look for key "type" in every object. Then we can convert a json object into a `User` subclass. Let's write these process down.

1. We have to know all the subclasses we want to decode.
2. Iterate through response array, for every object, we look for key "type", map this to one specific subclass.
3. Decode one object to target type.