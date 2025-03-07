// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -typecheck -verify -disable-availability-checking 2>&1 %s

// XFAIL: noncopyable_generics

// REQUIRES: concurrency
// REQUIRES: distributed

import Distributed

public final class CompletelyHollowActorSystem: DistributedActorSystem {
  // expected-error@-1{{type 'CompletelyHollowActorSystem' does not conform to protocol 'DistributedActorSystem'}}
  // expected-note@-2{{add stubs for conformance}}
  // expected-error@-3{{class 'CompletelyHollowActorSystem' is missing witness for protocol requirement 'remoteCall'}}
  // expected-note@-4{{add stubs for conformance}}
  // expected-error@-5{{class 'CompletelyHollowActorSystem' is missing witness for protocol requirement 'remoteCallVoid'}}

  public typealias ActorID = String
  public typealias InvocationEncoder = Encoder
  // expected-note@-1{{possibly intended match 'CompletelyHollowActorSystem.InvocationEncoder' (aka 'CompletelyHollowActorSystem.Encoder') does not conform to 'DistributedTargetInvocationEncoder'}}
  public typealias InvocationDecoder = Decoder
  // expected-note@-1{{possibly intended match 'CompletelyHollowActorSystem.InvocationDecoder' (aka 'CompletelyHollowActorSystem.Decoder') does not conform to 'DistributedTargetInvocationDecoder'}}

  public typealias SerializationRequirement = Codable

  public func actorReady<Act>(_ actor: Act) where Act : DistributedActor, ActorID == Act.ID {

  }

  public struct Encoder: InvocationEncoder {

  }

  public struct Decoder: InvocationDecoder {
  // expected-error@-1 {{inheritance from non-protocol type 'CompletelyHollowActorSystem.InvocationDecoder' (aka 'CompletelyHollowActorSystem.Decoder')}}

  }

  public struct ResultHandler: DistributedTargetInvocationResultHandler {
    // expected-error@-1{{type 'CompletelyHollowActorSystem.ResultHandler' does not conform to protocol 'DistributedTargetInvocationResultHandler'}}
    // expected-error@-2{{struct 'ResultHandler' is missing witness for protocol requirement 'onReturn'}}
    // expected-note@-3{{add stubs for conformance}}
  }

}

public final class CompletelyHollowActorSystem_NotEvenTypes: DistributedActorSystem {
  // expected-error@-1{{type 'CompletelyHollowActorSystem_NotEvenTypes' does not conform to protocol 'DistributedActorSystem'}}
  // expected-error@-2{{class 'CompletelyHollowActorSystem_NotEvenTypes' is missing witness for protocol requirement 'remoteCallVoid'}}
  // expected-error@-3{{class 'CompletelyHollowActorSystem_NotEvenTypes' is missing witness for protocol requirement 'remoteCall'}}
  // expected-note@-4{{add stubs for conformance}}
  // expected-note@-5{{add stubs for conformance}}
}