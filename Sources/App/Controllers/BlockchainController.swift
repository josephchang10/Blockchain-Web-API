import Foundation
import Vapor

class BlockchainController {
    private (set) var drop: Droplet
    private (set) var blockchainService: BlockchainService!

    init(drop: Droplet) {
        self.drop = drop
        self.blockchainService = BlockchainService()

        // 为控制器设置路由
        setupRoutes()
    }

    private func setupRoutes() {
        
        self.drop.get("nodes") { request in
            return try JSONEncoder().encode(self.blockchainService.getNodes())
        }
        
        self.drop.get("nodes/resolve") { request in
            return try Response.async { portal in
                self.blockchainService.resolve { blockchain in
                    let blockchain = try! JSONEncoder().encode(blockchain)
                    portal.close(with: blockchain.makeResponse())
                }
            }
        }
        
        self.drop.post("nodes/register") { request in
            guard let blockchainNode = BlockchainNode(request: request) else {
                return try JSONEncoder().encode(["message": "注册节点出现错误"])
            }
            
            self.blockchainService.registerNode(blockchainNode)
            return try JSONEncoder().encode(blockchainNode)
        }
        
        self.drop.get("mine") { request in
            let block = Block()
            self.blockchainService.addBlock(block)
            return try JSONEncoder().encode(block)
        }

        // 添加新交易
        self.drop.post("transaction") { request in
            if let transaction = Transaction(request: request) {
                // 添加交易至区块

                // 获得最后一个挖出的区块
                let block = self.blockchainService.getLastBlock()
                block.addTransaction(transaction: transaction)

                return try JSONEncoder().encode(block)
            }
            return try JSONEncoder().encode(["message": "发生异常！"])
        }

        // 获得链
        self.drop.get("blockchain") { request in
            if let blockchain = self.blockchainService.getBlockchain() {
                return try JSONEncoder().encode(blockchain)
            }

            return try! JSONEncoder().encode(["message":"区块链尚未初始化。请先挖矿"])
        }
    }
}
