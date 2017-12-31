import Foundation
import Vapor

let DIFFICULTY = "000"

class Transaction: Codable {
    var from: String
    var to: String
    var amount: Double

    init(from: String, to: String, amount: Double) {
        self.from = from
        self.to = to
        self.amount = amount
    }

    init?(request: Request) {
        guard let from = request.data["from"]?.string, let to = request.data["to"]?.string, let amount = request.data["amount"]?.double else {
            return nil
        }
        self.from = from
        self.to = to
        self.amount = amount
    }
}

class Block: Codable {
    var index: Int = 0
    var dateCreated: String
    var previousHash: String!
    var hash: String!
    var nonce: Int
    var message: String = ""
    private (set) var transactions: [Transaction] = [Transaction]()

    var key: String {
        get {
            let transactionsData = try! JSONEncoder().encode(self.transactions)
            let transactionsJSONString = String(data: transactionsData, encoding: .utf8)

            return String(self.index) + self.dateCreated + self.previousHash + transactionsJSONString! + String(self.nonce)
        }
    }

    func addTransaction(transaction: Transaction) {
        self.transactions.append(transaction)
    }

    init() {
        self.dateCreated = Date().toString()
        self.nonce = 0
        self.message = "挖出新的区块"
    }

    init(transaction: Transaction) {
        self.dateCreated = Date().toString()
        self.nonce = 0
        self.addTransaction(transaction: transaction)
    }
}

class BlockchainNode: Codable {
    var address: String
    
    init(address: String) {
        self.address = address
    }
    
    init?(request: Request) {
        guard let address = request.data["address"]?.string else {
            return nil
        }
        self.address = address
    }
}

class Blockchain: Codable {
    var blocks: [Block] = [Block]()
    var nodes :[BlockchainNode] = [BlockchainNode]()

    init() {

    }

    init(_ genesisBlock: Block) {
        self.addBlock(genesisBlock)
    }
    
    func addNode(_ blockchainNode :BlockchainNode) {
        self.nodes.append(blockchainNode)
    }

    func addBlock(_ block: Block) {
        if self.blocks.isEmpty {
            // 添加创世区块
            // 第一个区块没有 previous hash
            block.previousHash = "0"
        } else {
            let previousBlock = getPreviousBlock()
            block.previousHash = previousBlock.hash
            block.index = self.blocks.count
        }

        block.hash = generateHash(for: block)
        self.blocks.append(block)
        block.message = "此区块已添加至区块链"
    }

    private func getPreviousBlock() -> Block {
        return self.blocks[self.blocks.count - 1]
    }

    private func displayBlock(_ block: Block) {
        print("------ 第 \(block.index) 个区块 --------")
        print("创建日期：\(block.dateCreated)")
        // print("数据：\(block.data)")
        print("Nonce：\(block.nonce)")
        print("前一个区块的哈希值：\(block.previousHash!)")
        print("哈希值：\(block.hash!)")
    }

    private func generateHash(for block: Block) -> String {
        var hash = block.key.sha256()!

        // 设置工作量证明
        while(!hash.hasPrefix(DIFFICULTY)) {
            block.nonce += 1
            hash = block.key.sha256()!
            print(hash)
        }

        return hash
    }
}
