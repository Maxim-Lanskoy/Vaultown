//
//  NameGenerator.swift
//  GameLogic
//
//  Random name generation for dwellers with locale-specific ethnic variants
//

import Foundation

/// Generates random names for dwellers from predefined pools.
public enum NameGenerator {

    // MARK: - English (American) Names

    /// Male first names pool (English/American)
    public static let maleFirstNamesEN: [String] = [
        "Adam", "Brian", "Carl", "David", "Edward", "Frank", "George", "Henry",
        "Ivan", "Jack", "Kevin", "Larry", "Mike", "Nick", "Oscar", "Paul",
        "Quinn", "Roger", "Steve", "Tom", "Victor", "Walter", "Xavier", "Zach",
        "Albert", "Benjamin", "Charles", "Daniel", "Eugene", "Frederick",
        "Gabriel", "Harold", "Isaac", "James", "Kenneth", "Leonard", "Marcus",
        "Nathan", "Oliver", "Patrick", "Raymond", "Samuel", "Theodore", "Vincent",
        "William", "Alexander", "Brandon", "Christopher", "Douglas", "Ernest",
        "Luke", "Ethan", "Mason", "Logan", "Jackson", "Lucas", "Cooper", "Max"
    ]

    /// Female first names pool (English/American)
    public static let femaleFirstNamesEN: [String] = [
        "Alice", "Betty", "Carol", "Diana", "Emma", "Fiona", "Grace", "Helen",
        "Iris", "Julia", "Karen", "Laura", "Mary", "Nancy", "Olivia", "Patricia",
        "Rachel", "Sarah", "Tina", "Uma", "Victoria", "Wendy", "Zoe", "Amanda",
        "Barbara", "Catherine", "Dorothy", "Eleanor", "Florence", "Georgina",
        "Harriet", "Isabella", "Jennifer", "Katherine", "Lillian", "Margaret",
        "Natalie", "Ophelia", "Penelope", "Rebecca", "Stephanie", "Theresa",
        "Ursula", "Valerie", "Wanda", "Yvonne", "Abigail", "Beatrice", "Cecilia",
        "Chloe", "Sophie", "Mia", "Ava", "Charlotte", "Harper", "Scarlett", "Luna"
    ]

    /// Last names pool (English/American)
    public static let lastNamesEN: [String] = [
        "Adams", "Baker", "Clark", "Davis", "Edwards", "Fisher", "Garcia",
        "Harris", "Jackson", "King", "Lee", "Miller", "Nelson", "O'Brien",
        "Parker", "Quinn", "Roberts", "Smith", "Taylor", "Walker", "Young",
        "Anderson", "Brown", "Campbell", "Donovan", "Evans", "Ford",
        "Gibson", "Hughes", "Irving", "Johnson", "Kelly", "Lewis", "Mitchell",
        "Newman", "Olson", "Peterson", "Richardson", "Stevens", "Thompson",
        "Underwood", "Vasquez", "Williams", "Yates", "Zimmerman",
        "Armstrong", "Bennett", "Collins", "Dunn", "Elliott", "Foster",
        "Graham", "Hamilton", "Ingram", "Jones", "Kramer", "Lawrence",
        "Morrison", "Norton", "Owen", "Price", "Reed", "Sullivan", "Turner",
        "Valentine", "Watson", "York", "Zeller", "Abbott", "Bishop",
        "Carter", "Dixon", "Emerson", "Fleming", "Gordon", "Hawkins", "Jennings",
        "Klein", "Logan", "Mason", "Norris", "Owens", "Palmer", "Reeves",
        "Sanders", "Tucker", "Vaughn", "Warren", "Cooper", "Brooks", "Murphy"
    ]

    // MARK: - Ukrainian Names

    /// Male first names pool (Ukrainian)
    public static let maleFirstNamesUK: [String] = [
        "Олександр", "Андрій", "Богдан", "Василь", "Григорій", "Дмитро", "Євген",
        "Ігор", "Іван", "Кирило", "Максим", "Микола", "Олег", "Павло", "Петро",
        "Роман", "Сергій", "Степан", "Тарас", "Федір", "Юрій", "Ярослав",
        "Віктор", "Володимир", "В'ячеслав", "Денис", "Артем", "Назар", "Остап",
        "Данило", "Матвій", "Святослав", "Ростислав", "Олесь", "Зеновій",
        "Левко", "Любомир", "Михайло", "Орест", "Тимофій", "Захар", "Ілля",
        "Марко", "Давид", "Арсен", "Вадим", "Станіслав", "Георгій", "Антон"
    ]

    /// Female first names pool (Ukrainian)
    public static let femaleFirstNamesUK: [String] = [
        "Олена", "Анна", "Богдана", "Вікторія", "Галина", "Дарина", "Катерина",
        "Ірина", "Юлія", "Людмила", "Марія", "Надія", "Оксана", "Ольга", "Світлана",
        "Софія", "Тетяна", "Христина", "Яна", "Леся", "Зоряна", "Орися",
        "Наталія", "Валентина", "Любов", "Віра", "Лариса", "Тамара", "Злата",
        "Ярослава", "Мирослава", "Соломія", "Уляна", "Діана", "Аліна", "Анастасія",
        "Поліна", "Вероніка", "Єлизавета", "Емілія", "Мілана", "Злата", "Карина",
        "Роксолана", "Соломія", "Ангеліна", "Маргарита", "Дарія", "Іванна"
    ]

    /// Last names pool (Ukrainian)
    public static let lastNamesUK: [String] = [
        "Шевченко", "Коваленко", "Бойко", "Ткаченко", "Кравченко", "Олійник",
        "Шевчук", "Поліщук", "Бондаренко", "Ткачук", "Марченко", "Савченко",
        "Руденко", "Мельник", "Кравчук", "Мороз", "Клименко", "Левченко",
        "Гриценко", "Лисенко", "Петренко", "Сидоренко", "Павленко", "Кузьменко",
        "Гончаренко", "Степаненко", "Романенко", "Коваль", "Бондар", "Козак",
        "Гончар", "Заєць", "Вовк", "Сорока", "Лебідь", "Соловей", "Орел",
        "Хоменко", "Литвиненко", "Гордієнко", "Тимошенко", "Даниленко",
        "Семенченко", "Василенко", "Гнатенко", "Федоренко", "Яременко",
        "Карпенко", "Зінченко", "Панченко", "Шульга", "Дорошенко", "Тарасенко",
        "Макаренко", "Герасименко", "Нечипоренко", "Корнієнко", "Кириленко"
    ]

    // MARK: - Legendary Names (International)

    /// Legendary dweller names (fixed canonical names from Fallout)
    public static let legendaryNames: [(firstName: String, lastName: String, gender: Gender)] = [
        // Fallout 3
        ("Three Dog", "", .male),
        ("Sarah", "Lyons", .female),
        ("Butch", "DeLoria", .male),
        ("Moira", "Brown", .female),
        ("James", "", .male),
        ("Amata", "Almodovar", .female),
        ("Lucas", "Simms", .male),
        ("Jericho", "", .male),

        // Fallout 4
        ("Preston", "Garvey", .male),
        ("Piper", "Wright", .female),
        ("Nick", "Valentine", .male),
        ("Paladin", "Danse", .male),
        ("Hancock", "", .male),
        ("Cait", "", .female),
        ("Curie", "", .female),
        ("MacCready", "", .male),
        ("Deacon", "", .male),
        ("Strong", "", .male),
        ("Codsworth", "", .male),
        ("Dogmeat", "", .male),

        // Fallout 76
        ("Rose", "", .female),
        ("Grahm", "", .male),

        // TV Series
        ("Lucy", "MacLean", .female),
        ("Maximus", "", .male),
        ("The Ghoul", "", .male),
        ("Norm", "MacLean", .male),
        ("Hank", "MacLean", .male),
        ("Moldaver", "", .female),

        // Additional
        ("Elder", "Maxson", .male),
        ("Desdemona", "", .female),
        ("Father", "", .male),
        ("Kellogg", "", .male)
    ]

    // MARK: - Legacy Properties (Default to English)

    public static var maleFirstNames: [String] { maleFirstNamesEN }
    public static var femaleFirstNames: [String] { femaleFirstNamesEN }
    public static var lastNames: [String] { lastNamesEN }

    // MARK: - Name Generation

    /// Generate a random name for a dweller based on locale
    public static func randomName(gender: Gender, locale: String = "en") -> (firstName: String, lastName: String) {
        let (firstNames, lastNamesPool): ([String], [String])

        switch locale {
        case "uk":
            firstNames = gender == .male ? maleFirstNamesUK : femaleFirstNamesUK
            lastNamesPool = lastNamesUK
        default:
            firstNames = gender == .male ? maleFirstNamesEN : femaleFirstNamesEN
            lastNamesPool = lastNamesEN
        }

        let firstName = firstNames.randomElement() ?? (gender == .male ? "John" : "Jane")
        let lastName = lastNamesPool.randomElement() ?? "Doe"
        return (firstName, lastName)
    }

    /// Get a random legendary dweller name
    public static func randomLegendaryName() -> (firstName: String, lastName: String, gender: Gender) {
        legendaryNames.randomElement() ?? ("Unknown", "Legend", .male)
    }

    /// Generate full name string
    public static func fullName(firstName: String, lastName: String) -> String {
        if lastName.isEmpty {
            return firstName
        }
        return "\(firstName) \(lastName)"
    }

    /// Get all first names for a locale
    public static func allFirstNames(gender: Gender, locale: String = "en") -> [String] {
        switch locale {
        case "uk":
            return gender == .male ? maleFirstNamesUK : femaleFirstNamesUK
        default:
            return gender == .male ? maleFirstNamesEN : femaleFirstNamesEN
        }
    }

    /// Get all last names for a locale
    public static func allLastNames(locale: String = "en") -> [String] {
        switch locale {
        case "uk":
            return lastNamesUK
        default:
            return lastNamesEN
        }
    }
}
