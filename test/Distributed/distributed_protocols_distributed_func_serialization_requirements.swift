// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend-emit-module -emit-module-path %t/FakeDistributedActorSystems.swiftmodule -module-name FakeDistributedActorSystems -disable-availability-checking %S/Inputs/FakeDistributedActorSystems.swift
// RUN: %target-swift-frontend -typecheck -verify -verify-ignore-unknown -disable-availability-checking -I %t 2>&1 %s
// REQUIRES: concurrency
// REQUIRES: distributed

import Distributed
import FakeDistributedActorSystems

struct NotCodable {}

protocol NoSerializationRequirementYet: DistributedActor {
  distributed func test() -> NotCodable // FIXME(distributed): rdar://95949498 currently we are limited to explicitly 'async throws' protocol requirements that are distributed funcs
  // expected-error@-1{{'distributed' protocol requirement 'test()' must currently be declared explicitly 'async throws'}}

  // OK, no serialization requirement yet
  distributed func testAT() async throws -> NotCodable
}

distributed actor SpecifyRequirement: NoSerializationRequirementYet {
  typealias ActorSystem = FakeActorSystem

  // expected-error@+1{{result type 'NotCodable' of distributed instance method 'test' does not conform to serialization requirement 'Codable'}}
  distributed func test() -> NotCodable {
    .init()
  }

  // expected-error@+1{{result type 'NotCodable' of distributed instance method 'testAT' does not conform to serialization requirement 'Codable'}}
  distributed func testAT() async throws -> NotCodable {
    .init()
  }
}

extension NoSerializationRequirementYet {
  // Still OK, we don't know if this will be implementable or not
  distributed func test2() -> NotCodable {
    .init()
  }
}

extension NoSerializationRequirementYet
  where SerializationRequirement == Codable {
  // expected-error@+1{{result type 'NotCodable' of distributed instance method 'test3' does not conform to serialization requirement 'Codable'}}
  distributed func test3() -> NotCodable {
    .init()
  }
}

extension NoSerializationRequirementYet
  where SerializationRequirement: Codable {
  // expected-error@+1{{result type 'NotCodable' of distributed instance method 'test4' does not conform to serialization requirement 'Codable'}}
  distributed func test4() -> NotCodable {
    .init()
  }
}

// FIXME(distributed): remove the -verify-ignore-unknown
// <unknown>:0: error: unexpected error produced: instance method 'recordReturnType' requires that 'NotCodable' conform to 'Decodable'
// <unknown>:0: error: unexpected error produced: instance method 'recordReturnType' requires that 'NotCodable' conform to 'Encodable'
// <unknown>:0: error: unexpected error produced: instance method 'remoteCall(on:target:invocation:throwing:returning:)' requires that 'NotCodable' conform to 'Decodable'
// <unknown>:0: error: unexpected error produced: instance method 'remoteCall(on:target:invocation:throwing:returning:)' requires that 'NotCodable' conform to 'Encodable'
