// RUN: %target-swift-frontend %s \
// RUN: -emit-sil  \
// RUN: -enable-builtin-module \
// RUN: -enable-experimental-feature NonescapableTypes \
// RUN: -disable-experimental-parser-round-trip \
// RUN: -enable-experimental-feature NoncopyableGenerics \
// RUN: -enable-experimental-lifetime-dependence-inference | %FileCheck %s
// REQUIRES: asserts

struct BufferView : ~Escapable {
  let ptr: UnsafeRawBufferPointer
  let c: Int
  @_unsafeNonescapableResult
  init(_ ptr: UnsafeRawBufferPointer, _ c: Int) {
    self.ptr = ptr
    self.c = c
  }
// CHECK: sil hidden @$s28implicit_lifetime_dependence10BufferViewVyA2ChYlscfC : $@convention(method) (@guaranteed BufferView, @thin BufferView.Type) -> _scope(1) @owned BufferView {
  init(_ otherBV: borrowing BufferView) {
    self.ptr = otherBV.ptr
    self.c = otherBV.c
  }
// CHECK: sil hidden @$s28implicit_lifetime_dependence10BufferViewVyA2CYlicfC : $@convention(method) (@owned BufferView, @thin BufferView.Type) -> _inherit(1) @owned BufferView {
  init(_ otherBV: consuming BufferView) {
    self.ptr = otherBV.ptr
    self.c = otherBV.c
  }
// CHECK: sil hidden @$s28implicit_lifetime_dependence10BufferViewVyACSWYls_SaySiGhtcfC : $@convention(method) (UnsafeRawBufferPointer, @guaranteed Array<Int>, @thin BufferView.Type) -> _scope(1) @owned BufferView {
  init(_ ptr: UnsafeRawBufferPointer, _ a: borrowing Array<Int>) {
    self.ptr = ptr
    self.c = a.count
  }
}

struct MutableBufferView : ~Escapable, ~Copyable {
  let ptr: UnsafeMutableRawBufferPointer
  let c: Int
  @_unsafeNonescapableResult
  init(_ ptr: UnsafeMutableRawBufferPointer, _ c: Int) {
    self.ptr = ptr
    self.c = c
  }
}

func testBasic() {
  let a = [Int](repeating: 0, count: 4)
  a.withUnsafeBytes {
    let view = BufferView($0, a.count)
    let derivedView = derive(view)
    let newView = consumeAndCreate(derivedView)
    use(newView)    
  }
}

// CHECK: sil hidden @$s28implicit_lifetime_dependence6deriveyAA10BufferViewVADYlsF : $@convention(thin) (@guaranteed BufferView) -> _scope(1) @owned BufferView {
func derive(_ x: borrowing BufferView) -> BufferView {
  return BufferView(x.ptr, x.c)
}

// CHECK: sil hidden @$s28implicit_lifetime_dependence16consumeAndCreateyAA10BufferViewVADnYliF : $@convention(thin) (@owned BufferView) -> _inherit(1) @owned BufferView {
func consumeAndCreate(_ x: consuming BufferView) -> BufferView {
  return BufferView(x.ptr, x.c)
}

func use(_ x: borrowing BufferView) {}

struct Wrapper : ~Escapable {
  var _view: BufferView
  var view: BufferView {
// CHECK: sil hidden @$s28implicit_lifetime_dependence7WrapperV4viewAA10BufferViewVvr : $@yield_once @convention(method) (@guaranteed Wrapper) -> _scope(0) @yields @guaranteed BufferView {
    _read {
      yield _view
    }
// CHECK: sil hidden @$s28implicit_lifetime_dependence7WrapperV4viewAA10BufferViewVvM : $@yield_once @convention(method) (@inout Wrapper) -> _scope(0) @yields @inout BufferView {
    _modify {
      yield &_view
    }
  }
// CHECK: sil hidden @$s28implicit_lifetime_dependence7WrapperVyAcA10BufferViewVYlicfC : $@convention(method) (@owned BufferView, @thin Wrapper.Type) -> _inherit(1) @owned Wrapper {
  init(_ view: consuming BufferView) {
    self._view = view
  }
// CHECK: sil hidden @$s28implicit_lifetime_dependence7WrapperV8getView1AA10BufferViewVyYLsF : $@convention(method) (@guaranteed Wrapper) -> _scope(0) @owned BufferView {
  borrowing func getView1() -> BufferView {
    return _view
  }

// CHECK:sil hidden @$s28implicit_lifetime_dependence7WrapperV8getView2AA10BufferViewVyYLiF : $@convention(method) (@owned Wrapper) -> _inherit(0) @owned BufferView {
  consuming func getView2() -> BufferView {
    return _view
  }
}

struct Container1 : ~Copyable {
  let ptr: UnsafeRawBufferPointer
  let c: Int
// CHECK: sil hidden @$s28implicit_lifetime_dependence10Container1V4viewAA10BufferViewVvg : $@convention(method) (@guaranteed Container1) -> _scope(0) @owned BufferView {
  var view: BufferView {
    get {
      return BufferView(ptr, c)
    }
  }
}

struct Container2 : ~Copyable {
  let ptr: UnsafeMutableRawBufferPointer
  let c: Int
// CHECK: sil hidden @$s28implicit_lifetime_dependence10Container2V11mutableViewAA013MutableBufferF0Vvr : $@yield_once @convention(method) (@guaranteed Container2) -> _scope(0) @yields @guaranteed MutableBufferView {
  var mutableView: MutableBufferView {
    _read {
      yield MutableBufferView(ptr, c)
    }
  }
}


struct FakeRange<Bound> {
  public let lowerBound: Bound
  public let upperBound: Bound
}

struct GenericBufferView<Element> : ~Escapable {
  typealias Index = Int
  typealias Pointer = UnsafeRawPointer

  let baseAddress: Pointer
  let count: Int

// CHECK: sil hidden @$s28implicit_lifetime_dependence17GenericBufferViewV11baseAddress5count9dependsOnACyxGSVYls_Siqd__htclufC : $@convention(method) <Element><Storage> (UnsafeRawPointer, Int, @in_guaranteed Storage, @thin GenericBufferView<Element>.Type) -> _scope(1) @owned GenericBufferView<Element> {
  init<Storage>(baseAddress: Pointer,
                count: Int,
                dependsOn: borrowing Storage) {
    self = GenericBufferView<Element>(baseAddress: baseAddress,
                                      count: count)
  }
  // unsafe private API
  @_unsafeNonescapableResult
  init(baseAddress: Pointer, count: Int) {
    precondition(count >= 0, "Count must not be negative")
    self.baseAddress = baseAddress
    self.count = count
  } 
  subscript(position: Pointer) -> Element {
    get {
      if _isPOD(Element.self) {
        return position.loadUnaligned(as: Element.self)
      }
      else {
        return position.load(as: Element.self)
      }
    }
  }
// CHECK: sil hidden @$s28implicit_lifetime_dependence17GenericBufferViewVyACyxGAA9FakeRangeVySVGcig : $@convention(method) <Element> (FakeRange<UnsafeRawPointer>, @guaranteed GenericBufferView<Element>) -> _scope(0) @owned GenericBufferView<Element> {
  subscript(bounds: FakeRange<Pointer>) -> Self {
    get {
      GenericBufferView(
        baseAddress: UnsafeRawPointer(bounds.lowerBound),
        count: bounds.upperBound.distance(to:bounds.lowerBound) / MemoryLayout<Element>.stride
      )
    }
  }
}
