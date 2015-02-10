LlamaKit
========

Collection of must-have functional tools. Trying to be as lightweight as possible, hopefully providing a simple foundation that
more advanced systems can build on. LlamaKit is very Cocoa-focused. It is designed to work with common Cocoa paradigms, use names
that are understandable to Cocoa devs, integrate with Cocoa tools like GCD, and in general strive for a low-to-modest learning
curve for devs familiar with ObjC and Swift rather than Haskell and ML. There are more functionally beautiful toolkits out there
(see [Swiftz](https://github.com/maxpow4h/swiftz) and [Swift-Extras](https://github.com/CodaFi/Swift-Extras) for some nice
examples). LlamaKit intentionally is much less full-featured, and is focused only on things that come up commonly in Cocoa
development. (Within those restrictions, it hopes to be based as much as possible on the lessons of other FP languages, and I
welcome input from folks with deeper FP experience.)

Currently has a `Result` object, which is the most critical. (And in the end, it may be the *only* thing in the main module.)

LlamaKit should be considered highly experimental, pre-alpha, in development, I promise I will break you.

But the `Result` object is kind of nice already if you want to go ahead and use it. :D

(Note that I've moved the async objects, Future, Promise, Task, out of this repo. I'm working on them further, but they'll
go into some other repo like LlamaKit-async. This repo is meant to be very, very core stuff that almost everyone will want.
Async is too big for that.)
