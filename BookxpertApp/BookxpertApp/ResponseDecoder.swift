//
//  ResponseDecoder.swift
//  BookxpertApp
//
//  Created by mhaashim on 18/04/25.
//

struct ObjectsResponse: Decodable {
    let id: String
    let name: String
    let data: myData?
    
    enum CodingKeys: String, CodingKey {
        case name
        case data
        case id
    }
}

struct myData: Decodable {
    var color: String?
    var capacity: String?
    var generation: String?
    var price: String?
    var screenSize: String?
    var description: String?
    var strapColor: String?
    var caseSize: String?
    var capacitygb: String?
    var year: String?
    var cpuModel: String?
    var hardDiskSize:String?
    
    enum CodingKeys: String, CodingKey {
        case colorCap = "Color"
        case colorLow = "color"
        case capacityCap = "Capacity"
        case capacityLow = "capacity"
        case generationCap = "Generation"
        case generationLow = "generation"
        case priceCap = "Price"
        case priceLow = "price"
        case screenSize = "Screen size"
        case description = "Description"
        case strapColor = "Strap Colour"
        case caseSize = "Case Size"
        case capacitygb = "capacity GB"
        case cpuModel = "CPU model"
        case hardDiskSize = "Hard disk size"
        case year
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        self.color = (try? container.decode(String.self, forKey: .colorCap)) ?? (try? container.decode(String.self, forKey: .colorLow))
        
        self.capacity = (try? container.decode(String.self, forKey: .capacityCap)) ?? (try? container.decode(String.self, forKey: .capacityLow))
        self.price = (try? container.decode(String.self, forKey: .priceCap)) ?? (try? container.decode(String.self, forKey: .priceLow))
        self.screenSize = try? container.decode(String.self, forKey: .screenSize)
        self.description = try? container.decode(String.self, forKey: .description)
        self.strapColor = try? container.decode(String.self, forKey: .strapColor)
        self.caseSize = try? container.decode(String.self, forKey: .caseSize)
        self.capacitygb = try? container.decode(String.self, forKey: .capacitygb)
        self.year = try? container.decode(String.self, forKey: .year)
        self.cpuModel = try? container.decode(String.self, forKey: .cpuModel)
        self.hardDiskSize = try? container.decode(String.self, forKey: .hardDiskSize)
        self.generation = (try? container.decode(String.self, forKey: .generationCap)) ?? (try? container.decode(String.self, forKey: .generationLow))
        
    }
    
}
