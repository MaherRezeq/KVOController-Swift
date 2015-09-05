//
//  KVOController.swift
//  KVOController
//
//  Created by mohamede1945 on 6/20/15.
//  Copyright (c) 2015 Varaw. All rights reserved.
//

import Foundation

/// Represents the types of objects that can be observable.
public typealias Observable = NSObject

/// Represents the kvo controller object association key property.
private var KVOControllerObjectAssociationKey : UInt8 = 0

/**
*  An NSObject extension for simplyfing observing/unobserving operations.
*/
public extension NSObject {

    /**
    Start obeserving and retaining retainedObservable for the passed key path, options and observing block.

    :param: retainedObservable The retained observable parameter.
    :param: keyPath            The key path parameter.
    :param: options            The options parameter.
    :param: block              The block parameter.

    :returns: The observer controller, you can use it to unobserve.
    */
    public func observe<Observable : NSObject, PropertyType>(
        #retainedObservable: Observable,
        keyPath: String,
        options: NSKeyValueObservingOptions,
        block: ClosureObserverWay<Observable, PropertyType>.ObservingBlock) -> Controller<ClosureObserverWay<Observable, PropertyType>> {

            let closure = ClosureObserverWay(block: block)
            let controller = Controller(retainedObservable: retainedObservable, keyPath: keyPath, options: options, observerWay: closure)
            addObserver(controller)
            return controller
    }

    /**
    Start obeserving but don't retain nonretainedObservable object for the passed key path, options and observing block.

    :param: retainedObservable The retained observable parameter.
    :param: keyPath            The key path parameter.
    :param: options            The options parameter.
    :param: block              The block parameter.

    :returns: The observer controller, you can use it to unobserve.
    */
    public func observe<ObservableType : Observable, PropertyType>(
        #nonretainedObservable: ObservableType,
        keyPath: String,
        options: NSKeyValueObservingOptions,
        block: ClosureObserverWay<ObservableType, PropertyType>.ObservingBlock) -> Controller<ClosureObserverWay<ObservableType, PropertyType>> {

            let closure = ClosureObserverWay(block: block)
            let controller = Controller(nonretainedObservable: nonretainedObservable, keyPath: keyPath, options: options, observerWay: closure)
            addObserver(controller)
            return controller
    }

    /**
    Unobserve the passed observable for the passed key path.

    :param: observable The observable parameter.
    :param: keyPath    The key path parameter.
    */
    public func unobserve(observable: Observable, keyPath: String) {
        var observers = listOfObservers()

        for (index, observer) in enumerate(observers) {
            if observer.isObserving(observable, keyPath: keyPath) {
                // stop observing
                observer.unobserve()

                // remove observer
                observers.removeAtIndex(index)
                break
            }
        }

        if observers.count == 0 {
            removeObjectAssociation()
        }
    }

    /**
    Unobserve all.
    */
    public func unobserveAll() {
        for observer in listOfObservers() {
            observer.unobserve()
        }
        removeObjectAssociation()
    }

    /**
    Remove object association.
    */
    private func removeObjectAssociation() {
        objc_setAssociatedObject(self, &KVOControllerObjectAssociationKey, nil, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }

    /**
    List of observers.

    :returns: The list of observers.
    */
    private func listOfObservers() -> [KVOObserver] {
        var associatedObject : AnyObject? =  objc_getAssociatedObject(self, &KVOControllerObjectAssociationKey)
        var observers: [KVOObserver]
        if let associatedObject = associatedObject as? ObjectWrapper,
            observersArray = associatedObject.any as? [KVOObserver] {
            observers = observersArray
        } else {
            observers = [KVOObserver]()
        }
        return observers
    }

    /**
    Add observer.

    :param: observer The observer parameter.
    */
    private func addObserver(observer: KVOObserver) {
        var observers = listOfObservers()
        observers.append(observer)

        let wrapper = ObjectWrapper(any: observers)
        objc_setAssociatedObject(self, &KVOControllerObjectAssociationKey, wrapper, objc_AssociationPolicy(OBJC_ASSOCIATION_RETAIN_NONATOMIC))
    }

    /**
    Represents the object wrapper class.

    @author mohamede1945

    @version 1.0
    */
    private class ObjectWrapper {
        /// Represents the any property.
        var any: Any
        /**
        Initialize new instance with any.

        :param: any The any parameter.

        :returns: The new created instance.
        */
        init(any: Any) {
            self.any = any
        }
    }
}

/**
Represents the change data class.

@author mohamede1945

@version 1.0
*/
public struct ChangeData<T> : Printable {

    /// Represents the kind property.
    public let kind: NSKeyValueChange  // NSKeyValueChangeKindKey

    /// Represents the new value property.
    public let newValue: T?            // NSKeyValueChangeNewKey

    /// Represents the old value property.
    public let oldValue: T?            // NSKeyValueChangeOldKey

    /// Represents the indexes property.
    public let indexes: NSIndexSet?    // NSKeyValueChangeIndexesKey

    /// Represents the is prior property.
    public let isPrior: Bool           // NSKeyValueChangeNotificationIsPriorKey

    /// Represents the key path property.
    public let keyPath: String

    /**
    Initialize new instance with change and key path.

    :param: change  The change parameter.
    :param: keyPath The key path parameter.

    :returns: The new created instance.
    */
    init(change: [NSObject: AnyObject], keyPath: String) {

        // the key path
        self.keyPath = keyPath

        // mandatory
        kind = NSKeyValueChange(rawValue: change[NSKeyValueChangeKindKey]!.unsignedLongValue)!

        // optional
        newValue = change[NSKeyValueChangeNewKey] as? T
        oldValue = change[NSKeyValueChangeOldKey] as? T
        indexes  = change[NSKeyValueChangeIndexesKey] as? NSIndexSet

        if let prior = change[NSKeyValueChangeNotificationIsPriorKey] as? Bool {
            isPrior  = prior
        } else {
            isPrior = false
        }
    }

    /// Represents the description property.
    public var description: String {

        var description = "<Change kind: \(kindDescription(kind))"
        if isPrior {
            description += "prior: true"
        }
        if let newValue = newValue {
            description += " new: \(newValue)"
        }
        if let oldValue = oldValue {
            description += " old: \(oldValue)"
        }

        if let indexes = indexes {
            description += " indexes: \(indexes)"
        }
        description += ">"

        return description
    }
}

/**
Represents the observer way protocol.

@author mohamede1945

@version 1.0
*/
public protocol ObserverWay {

    /// Represents the ObservableType as generic type.
    typealias ObservableType : Observable
    /// Represents the PropertyType as generic type.
    typealias PropertyType

    /**
    Value changed change.

    :param: observable The observable parameter.
    :param: change     The change parameter.
    */
    func valueChanged(observable: ObservableType, change: ChangeData<PropertyType>)
}

/**
Represents the closure observer way class.

@author mohamede1945

@version 1.0
*/
public struct ClosureObserverWay<ObservableType : Observable, PropertyType> : ObserverWay {

    /**
    Represesnts the block signature to call when KVO fires.

    :param: observable The observable parameter.
    :param: change     The change parameter.
    */
    public typealias ObservingBlock = (observable: ObservableType, change: ChangeData<PropertyType>) -> ()

    /// Represents the block property.
    public let block: ObservingBlock

    /**
    Initialize new instance with block.

    :param: block The block parameter.

    :returns: The new created instance.
    */
    public init(block: ObservingBlock) {
        self.block = block
    }

    /**
    Value changed change.

    :param: observable The observable parameter.
    :param: change     The change parameter.
    */
    public func valueChanged(observable: ObservableType, change: ChangeData<PropertyType>) {
        block(observable: observable, change: change)
    }
}

/**
Represents the observable storage enumeration.

- Retained:    The retained parameter.
- Nonretained: The nonretained parameter.

@author mohamede1945

@version 1.0
*/
private enum ObservableStorage {
    case Retained
    case Nonretained
}

/**
Represents the KVO controller class.

@author mohamede1945

@version 1.0
*/
public class Controller<ObserverWay : ObserverWay> : _KVOObserver, KVOObserver, Printable {

    /// Represents the key path property.
    public let keyPath: String
    /// Represents the options property.
    public let options: NSKeyValueObservingOptions

    /// Represents the observer way property.
    public let observerWay: ObserverWay

    /// Represents the store property.
    private let store: ObservableStore<ObserverWay.ObservableType>

    /// Represents the observable property.
    public var observable: ObserverWay.ObservableType? {
        return store.observable
    }

    /// Represents the proxy property.
    private var proxy: ControllerProxy!

    /// Represents the observing property.
    public private(set) var observing = true

    /**
    Initialize new instance with observable, observable storage, key path, options, context and observer way.

    :param: observable        The observable parameter.
    :param: observableStorage The observable storage parameter.
    :param: keyPath           The key path parameter.
    :param: options           The options parameter.
    :param: context           The context parameter.
    :param: observerWay       The observer way parameter.

    :returns: The new created instance.
    */
    private init(
        observable  : ObserverWay.ObservableType,
        observableStorage: ObservableStorage,
        keyPath : String,
        options : NSKeyValueObservingOptions,
        context : UnsafeMutablePointer<Void> = nil,
        observerWay : ObserverWay) {

            assert(!keyPath.isEmpty, "Keypath shouldn't be empty string")

            self.keyPath = keyPath
            self.options = options
            self.observerWay = observerWay
            self.store = ObservableStore(observable: observable, storage: observableStorage)

            self.proxy = ControllerProxy(self)
            SharedObserverController.shared.observe(observable, observer: self.proxy)
    }

    /**
    Initialize new instance with retained observable, key path, options, context and observer way.

    :param: retainedObservable The retained observable parameter.
    :param: keyPath            The key path parameter.
    :param: options            The options parameter.
    :param: context            The context parameter.
    :param: observerWay        The observer way parameter.

    :returns: The new created instance.
    */
    public convenience init(retainedObservable: ObserverWay.ObservableType,
        keyPath : String,
        options : NSKeyValueObservingOptions,
        context : UnsafeMutablePointer<Void> = nil,
        observerWay : ObserverWay) {

            self.init(observable: retainedObservable, observableStorage: .Retained, keyPath : keyPath,
                options : options, context : context, observerWay: observerWay)
    }

    /**
    Initialize new instance with nonretained observable, key path, options, context and observer way.

    :param: nonretainedObservable The nonretained observable parameter.
    :param: keyPath               The key path parameter.
    :param: options               The options parameter.
    :param: context               The context parameter.
    :param: observerWay           The observer way parameter.

    :returns: The new created instance.
    */
    public convenience init(nonretainedObservable: ObserverWay.ObservableType,
        keyPath : String,
        options : NSKeyValueObservingOptions,
        context : UnsafeMutablePointer<Void> = nil,
        observerWay : ObserverWay) {

            self.init(observable: nonretainedObservable, observableStorage: .Nonretained, keyPath : keyPath,
                options : options, context : context, observerWay: observerWay)
    }

    /**
    Deallocate the instance.
    */
    deinit {
        unobserve()
    }

    /**
    Unobserve.
    */
    public func unobserve() {
        if let observable = observable where observing {
            SharedObserverController.shared.unobserve(observable, keyPath: keyPath, observer: self.proxy)
            observing = false
        }
    }

    /**
    Value changed change.

    :param: observable The observable parameter.
    :param: change     The change parameter.
    */
    private func valueChanged(observable: Observable, change: [NSObject : AnyObject]) {
        if let observableObject = self.observable where observing {
            let kvoChange = ChangeData<ObserverWay.PropertyType>(change: change, keyPath: keyPath)
            observerWay.valueChanged(observableObject, change: kvoChange)
        }
    }

    /**
    Whether or not is observing the passed key path.

    :param: observable The observable parameter.
    :param: keyPath    The key path parameter.

    :returns: True if observing, otherwise false.
    */
    public func isObserving(observable: Observable, keyPath: String) -> Bool {

        if let observableObject = self.observable where observing && keyPath == self.keyPath {
            return true
        }
        return false

    }

    /// Represents the description property.
    public var description: String {
        var description = "<Controller options: \(optionDescription(options)) keyPath: \(keyPath) observable: \(observable) observing: \(observing)>"
        return description
    }
}

// MARK:- Proxy and KVO Controllers

/**
Represents the controller proxy class.

@author mohamede1945

@version 1.0
*/
@objc
private class ControllerProxy: NSObject, _KVOObserver, Printable {

    /// Represents the observer property.
    unowned var observer: _KVOObserver

    /**
    Initialize new instance with_.

    :param: observer The observer parameter.

    :returns: The new created instance.
    */
    init(_ observer: _KVOObserver) {
        self.observer = observer
    }

    /// Represents the key path property.
    var keyPath: String {
        return observer.keyPath
    }

    /// Represents the options property.
    var options: NSKeyValueObservingOptions {
        return observer.options
    }

    /**
    Value changed change.

    :param: observable The observable parameter.
    :param: change     The change parameter.
    */
    func valueChanged(observable: Observable, change: [NSObject : AnyObject]) {
        return observer.valueChanged(observable, change: change)
    }

    /// Represents the pointer property.
    lazy var pointer: UnsafeMutablePointer<ControllerProxy> = {
        return UnsafeMutablePointer<ControllerProxy>(Unmanaged<ControllerProxy>.passUnretained(self).toOpaque())
        }()

    /**
    From pointer.

    :param: pointer The pointer parameter.

    :returns: The controller proxy.
    */
    class func fromPointer(pointer: UnsafeMutablePointer<ControllerProxy>) -> ControllerProxy {
        return Unmanaged<ControllerProxy>.fromOpaque(COpaquePointer(pointer)).takeUnretainedValue()
    }

    /// Represents the description property.
    override var description: String {
        var description = String(format: "<%@:%p observer: \(observer)>", arguments: [NSStringFromClass(self.dynamicType), self])
        return description
    }
}

/**
Represents the shared observer controller class.

@author mohamede1945

@version 1.0
*/
private class SharedObserverController : NSObject {
    /// Represents the observers property.
    let observers = NSHashTable.weakObjectsHashTable()
    /// Represents the lock property.
    var lock = OS_SPINLOCK_INIT

    /// Represents the shared property.
    static let shared = SharedObserverController()

    /**
    Observe var.

    :param: observable The observable parameter.
    :param: observer   The observer parameter.
    */
    func observe(observable: Observable, var observer: ControllerProxy) {

        executeSafely {NSPointerFunctionsOpaqueMemory
            observers.addObject(observer)
        }

        observable.addObserver(self, forKeyPath: observer.keyPath, options: observer.options, context: observer.pointer)
    }

    /**
    Unobserve key path and var.

    :param: observable The observable parameter.
    :param: keyPath    The key path parameter.
    :param: observer   The observer parameter.
    */
    func unobserve(observable: Observable, keyPath: String, var observer: ControllerProxy) {
        executeSafely {
            observers.removeObject(observer)
        }

        observable.removeObserver(self, forKeyPath: keyPath)
    }

    /**
    Observe value for key path of object, change and context.

    :param: keyPath    The key path parameter.
    :param: observable The observable parameter.
    :param: change     The change parameter.
    :param: context    The context parameter.
    */
    override func observeValueForKeyPath(keyPath: String, ofObject observable: AnyObject,
        change: [NSObject : AnyObject], context: UnsafeMutablePointer<Void>) {

            assert(context != nil,
                "Context is missing for keyPath:'\(keyPath)' of observable:'\(observable)', change:'\(change)'")
            assert(observable is NSObject, "Observable object should be of type NSObject")

            let observableObject = observable as! NSObject

            let pointer = UnsafeMutablePointer<ControllerProxy>(context)
            let contextObserver = ControllerProxy.fromPointer(pointer)
            var info: ControllerProxy?
            executeSafely {
                info = observers.member(contextObserver) as? ControllerProxy
            }

            if let info = info {
                info.valueChanged(observableObject, change: change)
            }
    }

    /**
    Execute safely@noescape.

    :param: block The block parameter.
    */
    private func executeSafely(@noescape block: () -> ()) {
        OSSpinLockLock(&lock)
        block()
        OSSpinLockUnlock(&lock)
    }

    /// Represents the description property.
    override var description: String {
        var description = String(format: "<%@:%p", arguments: [NSStringFromClass(self.dynamicType), self])
        executeSafely {

            var observersDescriptions = [String]()
            for observer in observers.objectEnumerator() {
                if let proxy = observer as? ControllerProxy {
                    observersDescriptions.append(proxy.description)
                }
            }

            description += " contexts:\(observersDescriptions)>"
        }

        return description
    }
}

/**
Represents the kvo observer protocol.

@author mohamede1945

@version 1.0
*/
public protocol KVOObserver {

    /**
    Unobserve.
    */
    func unobserve()
    /**
    Is observing key path.

    :param: observable The observable parameter.
    :param: keyPath    The key path parameter.

    :returns: True, if observing.
    */
    func isObserving(observable: Observable, keyPath: String) -> Bool
}

/**
Represents the private kvo observer protocol.

@author mohamede1945

@version 1.0
*/
private protocol _KVOObserver : class {
    /// Represents the key path property.
    var keyPath: String { get }
    /// Represents the options property.
    var options: NSKeyValueObservingOptions { get }
    /**
    Value changed change.

    :param: observable The observable parameter.
    :param: change     The change parameter.
    */
    func valueChanged(observable: Observable, change: [NSObject : AnyObject])
}

/**
Represents the observable store class.

@author mohamede1945

@version 1.0
*/
private struct ObservableStore<T : Observable> {

    /// Represents the storage property.
    private (set) var storage: ObservableStorage

    /// Represents the retained observable property.
    private var retainedObservable: T?
    /// Represents the nonretained observable property.
    private weak var nonretainedObservable: T?

    /**
    Initialize new instance with observable and storage.

    :param: observable The observable parameter.
    :param: storage    The storage parameter.

    :returns: The new created instance.
    */
    init(observable: T, storage: ObservableStorage) {
        self.storage = storage

        switch storage {
        case .Retained:     retainedObservable = observable
        case .Nonretained:  nonretainedObservable = observable
        }
    }

    /// Represents the observable property.
    var observable : T? {
        switch storage {
        case .Retained: return retainedObservable
        case .Nonretained: return nonretainedObservable
        }
    }
}

/**
Option description.

:param: option The option parameter.

:returns: The description of the option.
*/
private func optionDescription(option: NSKeyValueObservingOptions) -> String {
    var string = ""

    let options = [(option: NSKeyValueObservingOptions.New, "New"),
        (option: NSKeyValueObservingOptions.Old, "Old"),
        (option: NSKeyValueObservingOptions.Initial, "Initial"),
        (option: NSKeyValueObservingOptions.Prior, "Prior")]

    var varOption = option

    while varOption.rawValue > 0 {
        for (targetOption, desc) in options {
            if varOption & targetOption == targetOption {
                varOption = (~targetOption & varOption)
                string += desc + "|"
            }
        }
    }

    if !string.isEmpty {
        string.removeAtIndex(string.endIndex.predecessor())
    }

    return string;
}

/**
Kind description.

:param: kind The kind parameter.
*/
private func kindDescription(kind: NSKeyValueChange) -> String {
    let kinds = [NSKeyValueChange.Insertion: "Insertion",
        NSKeyValueChange.Removal: "Removal", NSKeyValueChange.Replacement : "Replacement", NSKeyValueChange.Setting : "Setting" ]
    return kinds[kind] ?? "Unknown Value: \(kind)"
}
