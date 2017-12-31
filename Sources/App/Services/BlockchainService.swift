import Foundation
import Vapor

class BlockchainService {
    
    typealias JSONDictionary = [String:String]
    private var blockchain: Blockchain = Blockchain()
    
    init() {

    }

    func addBlock(_ block: Block) {
        self.blockchain.addBlock(block)
    }
    
    func resolve(completion: @escaping(Blockchain) -> ()) {
        //获取节点
        let nodes = self.blockchain.nodes
        
        for node in nodes {
            let url = URL(string: "http://\(node.address)/blockchain")!
            URLSession.shared.dataTask(with: url, completionHandler: { (data, _, _) in
                if let data = data {
                    let blockchain = try! JSONDecoder().decode(Blockchain.self, from: data)
                    
                    if self.blockchain.blocks.count > blockchain.blocks.count {
                        completion(self.blockchain)
                    } else {
                        self.blockchain.blocks = blockchain.blocks
                        completion(blockchain)
                    }
                }
            }).resume()
        }
    }
    
    func getNodes() -> [BlockchainNode] {
        return self.blockchain.nodes
    }
    
    func registerNode(_ blockchainNode: BlockchainNode) {
        self.blockchain.addNode(blockchainNode)
    }

    func getLastBlock() -> Block {
        return self.blockchain.blocks.last!
    }

    func getBlockchain() -> Blockchain? {
        return self.blockchain
    }
}
