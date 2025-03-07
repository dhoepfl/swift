// RUN: %empty-directory(%t)
// RUN: %target-swift-frontend -emit-module -o %t  %S/Inputs/def_implicit_lifetime_dependence.swift \
// RUN: -enable-experimental-feature NonescapableTypes \
// RUN: -disable-experimental-parser-round-trip \
// RUN: -enable-experimental-feature NoncopyableGenerics

// RUN: llvm-bcanalyzer %t/def_implicit_lifetime_dependence.swiftmodule 

// RUN: %target-swift-frontend -module-name lifetime-dependence -emit-silgen -I %t %s \
// RUN: -enable-experimental-feature NonescapableTypes \
// RUN: -disable-experimental-parser-round-trip \
// RUN: -enable-experimental-feature NoncopyableGenerics \
// RUN: -enable-experimental-lifetime-dependence-inference | %FileCheck %s



import def_implicit_lifetime_dependence

func use(_ x: borrowing BufferView) {}
func mutate(_ x: inout BufferView) {}

func testBasic() {
  let a = [Int](repeating: 0, count: 4)
  a.withUnsafeBytes {
    let view = BufferView($0, a.count)
    let derivedView = derive(view)
    let consumedView = consumeAndCreate(derivedView)
    let borrowedView = borrowAndCreate(consumedView) 
    use(borrowedView)
  }
}

func testInitializers() {
  let a = [Int](repeating: 0, count: 4)
  a.withUnsafeBytes {
    let view1 = BufferView($0, a.count)
    let view2 = BufferView(view1)
    let view3 = BufferView(view2)
    use(view3)
  }
}

func unsafetest(_ ptr: UnsafeRawBufferPointer, _ c: Int) {
  let view1 = BufferView(ptr, c)
  let view2 = BufferView(view1)
  let view3 = BufferView(view2)
  use(view3)
}

func testGetter() {
  let a = [Int](repeating: 0, count: 4)
  a.withUnsafeBytes {
    let c = Container($0, a.count)
    let view = c.view
    use(view)
  }
}

func testReadmutateAccessors() {
  let a = [Int](repeating: 0, count: 4)
  a.withUnsafeBytes {
    let view = BufferView($0, a.count)
    var c = Wrapper(view)
    use(c.view)
    mutate(&c.view)
  }
}

// CHECK: sil @$s32def_implicit_lifetime_dependence6deriveyAA10BufferViewVADYlsF : $@convention(thin) (@guaranteed BufferView) -> _scope(1) @owned BufferView

// CHECK: sil @$s32def_implicit_lifetime_dependence16consumeAndCreateyAA10BufferViewVADnYliF : $@convention(thin) (@owned BufferView) -> _inherit(1) @owned BufferView

// CHECK: sil @$s32def_implicit_lifetime_dependence15borrowAndCreateyAA10BufferViewVADYlsF : $@convention(thin) (@guaranteed BufferView) -> _scope(1) @owned BufferView

// CHECK: sil @$s32def_implicit_lifetime_dependence10BufferViewVyA2ChYlscfC : $@convention(method) (@guaranteed BufferView, @thin BufferView.Type) -> _scope(1) @owned BufferView

// CHECK: sil @$s32def_implicit_lifetime_dependence9ContainerV4viewAA10BufferViewVvg : $@convention(method) (@guaranteed Container) -> _scope(0) @owned BufferView

// CHECK: sil @$s32def_implicit_lifetime_dependence7WrapperV4viewAA10BufferViewVvr : $@yield_once @convention(method) (@guaranteed Wrapper) -> _scope(0) @yields @guaranteed BufferView

// CHECK: sil @$s32def_implicit_lifetime_dependence7WrapperV4viewAA10BufferViewVvM : $@yield_once @convention(method) (@inout Wrapper) -> _scope(0) @yields @inout BufferView
