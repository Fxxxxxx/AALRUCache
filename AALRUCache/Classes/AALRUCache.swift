//
//  AALRUCache.swift
//  AALRUCache
//
//  Created by cztv on 2019/9/5.
//

public class AALRUCache<K: Hashable, V: Equatable> {
    typealias Node = ListNode<K, V>
    private var dic = [K: Node]()
    private var head: Node?
    private var tail: Node?
    private let maxCount: Int!
    private let lock = NSLock.init()
    
    public init(_ capacity: Int) {
        maxCount = capacity
    }
    
    public func get(_ key: K) -> V? {
        lock.lock()
        if let node = dic[key] {
            bringToFirst(node)
            lock.unlock()
            return node.val
        }
        lock.unlock()
        return nil
    }
    
    public func put(_ key: K, _ value: V) {
        lock.lock()
        if let node = dic[key] {
            node.val = value
            bringToFirst(node)
        } else {
            if dic.count == maxCount {
                dic.removeValue(forKey: tail!.key)
                tail = tail?.pre
                tail?.next = nil
            }
            let node = ListNode.init(key, value)
            node.next = head
            head?.pre = node
            head = node
            dic[key] = node
            if dic.count == 1 {
                tail = head
            }
        }
        lock.unlock()
    }
    
    private func bringToFirst(_ node: Node) {
        guard dic.count > 1 else {
            return
        }
        guard node !== head else {
            return
        }
        if tail === node {
            tail = node.pre
        }
        node.pre?.next = node.next
        node.next?.pre = node.pre
        node.next = head
        head?.pre = node
        head = node
        head?.pre = nil
    }
}

public extension AALRUCache {
    subscript(_ key: K) -> V? {
        get {
            return get(key)
        }
        set {
            guard let newV = newValue else {
                remove(key)
                return
            }
            put(key, newV)
        }
    }
    
    func append(_ key: K, _ value: V) {
        put(key, value)
    }
    
    func removeAll() {
        lock.lock()
        dic.removeAll()
        head = nil
        tail = nil
        lock.unlock()
    }
    
    @discardableResult
    func remove(_ key: K) -> V? {
        lock.lock()
        if let node = dic[key] {
            if head === node {
                head = node.next
                head?.pre = nil
            } else if tail === node {
                tail = node.pre
                tail?.next = nil
            } else {
                node.pre?.next = node.next
                node.next?.pre = node.pre
            }
            dic.removeValue(forKey: key)
            lock.unlock()
            return node.val
        }
        lock.unlock()
        return nil
    }
    
    func key(for value: V) -> K? {
        lock.lock()
        let result = dic.first(where: { (set) -> Bool in
            return value == set.value.val
        })?.key
        lock.unlock()
        return result
    }
}

extension AALRUCache {
    public var count: Int {
        lock.lock()
        let count = dic.count
        lock.unlock()
        return count
    }
    
    public var keys: [K] {
        lock.lock()
        let keys = Array(dic.keys)
        lock.unlock()
        return keys
    }
    
    public var values: [V] {
        lock.lock()
        let values = dic.values.map { (node) -> V in
            node.val
        }
        lock.unlock()
        return values
    }
}
