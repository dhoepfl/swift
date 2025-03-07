// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -swift-version 5 -emit-module-path %t/SerializedDefaultArguments.swiftmodule -module-name SerializedDefaultArguments -enable-upcoming-feature IsolatedDefaultValues %S/Inputs/serialized_default_arguments.swift

// RUN: %target-swift-frontend %s -emit-sil -o /dev/null -verify -disable-availability-checking -swift-version 6 -I %t
// RUN: %target-swift-frontend %s -emit-sil -o /dev/null -verify -disable-availability-checking -swift-version 6 -I %t -enable-experimental-feature RegionBasedIsolation -enable-upcoming-feature IsolatedDefaultValues

// REQUIRES: concurrency

import SerializedDefaultArguments

@MainActor 
func mainActorCaller() {
  useMainActorDefault()
  useNonisolatedDefault()
}

func nonisolatedCaller() async {
  await useMainActorDefault()

  await useMainActorDefault(mainActorDefaultArg())

  await useNonisolatedDefault()
}
