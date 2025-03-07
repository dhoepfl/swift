// REQUIRES: swift_swift_parser, asserts
//
// UNSUPPORTED: back_deploy_concurrency
// REQUIRES: concurrency
// REQUIRES: distributed
//
// RUN: %empty-directory(%t)
// RUN: %empty-directory(%t-scratch)

// RUN: %target-swift-frontend -typecheck -verify -disable-availability-checking -plugin-path %swift-plugin-dir -I %t -dump-macro-expansions %s 2>&1 | %FileCheck %s

import Distributed

typealias System = LocalTestingDistributedActorSystem

@_DistributedProtocol
protocol EmptyBase {}

// @_DistributedProtocol ->
//
// CHECK: distributed actor $EmptyBase<ActorSystem>: EmptyBase,
// CHECK:   Distributed._DistributedActorStub
// CHECK:   where ActorSystem: DistributedActorSystem<any Codable>,
// CHECK:         ActorSystem.ActorID: Codable
// CHECK:  {
// CHECK:  }

// CHECK: extension EmptyBase where Self: Distributed._DistributedActorStub {
// CHECK: }

// ==== ------------------------------------------------------------------------

@_DistributedProtocol
protocol G3<ActorSystem>: DistributedActor, EmptyBase where ActorSystem: DistributedActorSystem<any Codable> {
  distributed func get() -> String
  distributed func greet(name: String) -> String
}

// @_DistributedProtocol ->
// CHECK: distributed actor $G3<ActorSystem>: G3
// CHECK:   Distributed._DistributedActorStub
// CHECK:   where ActorSystem: DistributedActorSystem<any Codable>,
// CHECK:         ActorSystem.ActorID: Codable
// CHECK: {
// CHECK: }

// CHECK: extension G3 where Self: Distributed._DistributedActorStub {
// CHECK:   func get() -> String {
// CHECK:     if #available (SwiftStdlib 5.11, *) {
// CHECK:       Distributed._distributedStubFatalError()
// CHECK:     } else {
// CHECK:       fatalError()
// CHECK:     }
// CHECK:   }
// CHECK:   distributed func greet(name: String) -> String {
// CHECK:     if #available (SwiftStdlib 5.11, *) {
// CHECK:       Distributed._distributedStubFatalError()
// CHECK:     } else {
// CHECK:       fatalError()
// CHECK:     }
// CHECK:   }
// CHECK: }

