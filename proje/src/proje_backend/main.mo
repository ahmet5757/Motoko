import Result "mo:base/Result";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import HashMap "mo:base/HashMap";
import Time "mo:base/Time";
import Buffer "mo:base/Buffer";
import Hash "mo:base/Hash";
import Iter "mo:base/Iter";

actor StreetAnimalProtectionSystem {
  // Hayvan veri yapısı
  public type Animal = {
    id : Text;
    name : Text;
    animalType : Text;
    gender : Text;
    age : Nat;
    healthStatus : Text;
    location : Text;
    registrationDate : Time.Time;
  };

  // Besleme kaydı veri yapısı
  public type FeedingRecord = {
    id : Text;
    animalId : Text;
    location : Text;
    amount : Text;
    date : Time.Time;
  };

  // Yerel veri depoları
  private var animals = HashMap.HashMap<Text, Animal>(10, Text.equal, Text.hash);
  private var feedingRecords = HashMap.HashMap<Text, FeedingRecord>(10, Text.equal, Text.hash);

  // Hayvan ekleme işlevi
  public shared(msg) func addAnimal(
    name : Text, 
    animalType : Text, 
    gender : Text, 
    age : Nat, 
    location : Text
  ) : async Result.Result<Text, Text> {
    // Girdi doğrulamaları
    if (Text.size(name) == 0) {
      return #err("İsim boş olamaz");
    };

    if (Text.size(animalType) == 0) {
      return #err("Hayvan türü boş olamaz");
    };

    let animalId = generateUniqueId();
    let newAnimal : Animal = {
      id = animalId;
      name = name;
      animalType = animalType;
      gender = gender;
      age = age;
      healthStatus = "Normal";
      location = location;
      registrationDate = Time.now();
    };

    animals.put(animalId, newAnimal);
    #ok(animalId)
  };

  // Besleme kaydı ekleme işlevi
  public shared(msg) func addFeedingRecord(
    animalId : Text, 
    location : Text, 
    amount : Text
  ) : async Result.Result<Text, Text> {
    // Hayvanın var olup olmadığını kontrol et
    switch (animals.get(animalId)) {
      case null { return #err("Geçersiz hayvan ID'si"); };
      case (?_) {};
    };

    let recordId = generateUniqueId();
    let newFeedingRecord : FeedingRecord = {
      id = recordId;
      animalId = animalId;
      location = location;
      amount = amount;
      date = Time.now();
    };

    feedingRecords.put(recordId, newFeedingRecord);
    #ok(recordId)
  };

  // Hayvan sağlık durumu güncelleme
  public shared(msg) func updateAnimalHealth(
    animalId : Text, 
    newHealthStatus : Text
  ) : async Result.Result<(), Text> {
    switch (animals.get(animalId)) {
      case null { return #err("Hayvan bulunamadı"); };
      case (?animal) {
        let updatedAnimal : Animal = {
          id = animal.id;
          name = animal.name;
          animalType = animal.animalType;
          gender = animal.gender;
          age = animal.age;
          healthStatus = newHealthStatus;
          location = animal.location;
          registrationDate = animal.registrationDate;
        };
        animals.put(animalId, updatedAnimal);
        #ok()
      };
    };
  };

  // Tüm hayvanları listeleme
  public query func listAnimals() : async [Animal] {
    Iter.toArray(animals.vals())
  };

  // Belirli bir hayvanın besleme kayıtlarını listeleme
  public query func listAnimalFeedingRecords(animalId : Text) : async [FeedingRecord] {
    Iter.toArray(
      Iter.filter(
        feedingRecords.vals(), 
        func(record : FeedingRecord) : Bool { record.animalId == animalId }
      )
    )
  };

  // Rapor oluşturma
  public query func generateReport() : async {
    totalAnimals : Nat;
    animalTypeDistribution : [(Text, Nat)];
    healthStatusDistribution : [(Text, Nat)];
  } {
    let animalList = Iter.toArray(animals.vals());
    
    // Tür dağılımı
    let typeDistribution = Buffer.Buffer<(Text, Nat)>(0);
    let typeMap = HashMap.HashMap<Text, Nat>(10, Text.equal, Text.hash);

    for (animal in animalList.vals()) {
      switch (typeMap.get(animal.animalType)) {
        case null { typeMap.put(animal.animalType, 1); };
        case (?count) { typeMap.put(animal.animalType, count + 1); };
      };
    };

    // Sağlık durumu dağılımı
    let healthMap = HashMap.HashMap<Text, Nat>(10, Text.equal, Text.hash);
    for (animal in animalList.vals()) {
      switch (healthMap.get(animal.healthStatus)) {
        case null { healthMap.put(animal.healthStatus, 1); };
        case (?count) { healthMap.put(animal.healthStatus, count + 1); };
      };
    };

    {
      totalAnimals = animals.size();
      animalTypeDistribution = Iter.toArray(typeMap.entries());
      healthStatusDistribution = Iter.toArray(healthMap.entries());
    }
  };

  // Benzersiz ID oluşturma yardımcı işlevi
  private func generateUniqueId() : Text {
    Text.concat(
      "ANIMAL_", 
      Nat.toText(Hash.hash(Text.hash(debug_show(Time.now()))))
    )
  };

  // Hayvan silme (opsiyonel)
  public shared(msg) func removeAnimal(animalId : Text) : async Result.Result<(), Text> {
    switch (animals.get(animalId)) {
      case null { #err("Hayvan bulunamadı"); };
      case (?_) { 
        animals.delete(animalId);
        // İlişkili besleme kayıtlarını da sil
        let updatedFeedingRecords = Buffer.Buffer<FeedingRecord>(0);
        for (record in feedingRecords.vals()) {
          if (record.animalId != animalId) {
            updatedFeedingRecords.add(record);
          };
        };
        #ok()
      };
    }
  };
}