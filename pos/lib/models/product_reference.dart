class ProductReference {
  static final Map<String, List<String>> productNamesByCategory = {
    // ===== MEDICINES =====
    'Medicines': [
      // Pain Relief
      'Paracetamol',
      'Ibuprofen',
      'Aspirin',
      'Diclofenac Sodium',
      'Mefenamic Acid',
      'Naproxen',
      'Acetaminophen',
      'Codeine Phosphate',
      'Tramadol',
      'Morphine Sulfate',
      
      // Antibiotics
      'Amoxicillin',
      'Ciprofloxacin',
      'Azithromycin',
      'Doxycycline',
      'Clindamycin',
      'Metronidazole',
      'Cephalexin',
      'Levofloxacin',
      'Ceftriaxone',
      'Gentamicin',
      
      // Blood Pressure
      'Amlodipine',
      'Lisinopril',
      'Losartan',
      'Metoprolol',
      'Enalapril',
      'Ramipril',
      'Valsartan',
      'Hydrochlorothiazide',
      'Furosemide',
      'Spironolactone',
      
      // Diabetes
      'Metformin',
      'Insulin Glargine',
      'Glimepiride',
      'Gliclazide',
      'Sitagliptin',
      'Empagliflozin',
      'Dapagliflozin',
      'Pioglitazone',
      'Acarbose',
      'Repaglinide',
      
      // Heart/Cholesterol
      'Atorvastatin',
      'Rosuvastatin',
      'Simvastatin',
      'Clopidogrel',
      'Digoxin',
      'Warfarin',
      'Nitroglycerin',
      'Dabigatran',
      'Rivaroxaban',
      'Aspirin',
      
      // Respiratory
      'Salbutamol Inhaler',
      'Budesonide Inhaler',
      'Montelukast',
      'Fluticasone',
      'Theophylline',
      'Prednisolone',
      'Dexamethasone',
      'Hydrocortisone',
      'Beclomethasone',
      'Ipratropium',
      
      // Stomach/Ulcer
      'Omeprazole',
      'Pantoprazole',
      'Ranitidine',
      'Cimetidine',
      'Domperidone',
      'Metoclopramide',
      'Ondansetron',
      'Lansoprazole',
      'Esomeprazole',
      'Sucralfate',
      
      // Vitamins & Supplements
      'Vitamin C',
      'Vitamin D3',
      'Vitamin E',
      'Calcium Carbonate',
      'Iron Supplement',
      'Zinc',
      'Magnesium',
      'Folic Acid',
      'Omega-3 Fish Oil',
      'Multivitamin',
      
      // Skin/Creams
      'Hydrocortisone Cream',
      'Clotrimazole Cream',
      'Miconazole Cream',
      'Betamethasone Cream',
      'Neosporin Ointment',
      'Retin-A Cream',
      'Ketoconazole Cream',
      'Tretinoin Cream',
      'Benzoyl Peroxide',
      'Salicylic Acid',
      
      // Eye/Ear
      'Tobramycin Eye Drops',
      'Ciprofloxacin Eye Drops',
      'Dexamethasone Eye Drops',
      'Artificial Tears',
      'Ofloxacin Eye Drops',
      'Chloramphenicol Eye Drops',
      'Betamethasone Ear Drops',
      'Ciprofloxacin Ear Drops',
      'Clotrimazole Ear Drops',
      'Hydrocortisone Ear Drops',
    ],

    // ===== ELECTRONICS =====
    'Electronics': [
      // Smartphones
      'Samsung Galaxy S24 Ultra',
      'Samsung Galaxy S24 Plus',
      'Samsung Galaxy S24',
      'Samsung Galaxy A55',
      'Samsung Galaxy A35',
      'Samsung Galaxy Z Fold 5',
      'Samsung Galaxy Z Flip 5',
      'iPhone 15 Pro Max',
      'iPhone 15 Pro',
      'iPhone 15 Plus',
      'iPhone 15',
      'Google Pixel 8 Pro',
      'Google Pixel 8',
      'Xiaomi 13 Pro',
      'Xiaomi Redmi Note 13',
      'OnePlus 12',
      'OnePlus 11',
      'Realme GT Neo 5',
      'Motorola Edge 40 Pro',
      'Nothing Phone 2',
      'Sony Xperia 1 V',
      'Vivo X100 Pro',
      'Oppo Find X7 Ultra',
      
      // Laptops
      'MacBook Air M3',
      'MacBook Pro 14" M3',
      'MacBook Pro 16" M3',
      'Dell XPS 13 Plus',
      'Dell XPS 15',
      'HP Spectre x360 14',
      'HP Envy 16',
      'Lenovo ThinkPad X1 Carbon',
      'Lenovo Yoga 9i',
      'Lenovo Legion 5 Pro',
      'ASUS ROG Zephyrus G16',
      'ASUS Zenbook 14 OLED',
      'Acer Swift Go 14',
      'Acer Predator Helios 16',
      'Microsoft Surface Laptop 5',
      'MSI Stealth 16',
      'Razer Blade 16',
      'Samsung Galaxy Book 3 Pro',
      
      // Tablets
      'iPad Pro 12.9" M2',
      'iPad Pro 11" M2',
      'iPad Air 5',
      'iPad 10th Gen',
      'iPad Mini 6',
      'Samsung Galaxy Tab S9 Ultra',
      'Samsung Galaxy Tab S9 Plus',
      'Samsung Galaxy Tab S9',
      'Lenovo Tab P12',
      'Xiaomi Pad 6',
      'Microsoft Surface Pro 9',
      'Google Pixel Tablet',
      'OnePlus Pad',
      
      // Audio
      'AirPods Pro 2',
      'AirPods Max',
      'Samsung Galaxy Buds 2 Pro',
      'Sony WH-1000XM5',
      'Sony WF-1000XM5',
      'Bose QuietComfort 45',
      'Beats Studio Buds Plus',
      'JBL Tune 770NC',
      'JBL Flip 6',
      'Marshall Woburn III',
      'Skullcandy Crusher ANC 2',
      'Nothing Ear 2',
      'Google Pixel Buds Pro',
      'OnePlus Buds Pro 2',
      'Sennheiser HD 660S',
      
      // TVs
      'Samsung QLED QN90C 55"',
      'Samsung QLED QN90C 65"',
      'Samsung S95C OLED 55"',
      'LG C3 OLED 55"',
      'LG G3 OLED 65"',
      'Sony A95L OLED 55"',
      'Sony A80L OLED 65"',
      'TCL QM8 Mini-LED 65"',
      'Hisense U8K Mini-LED 65"',
      'Samsung Frame 55"',
      'Samsung Frame 65"',
      
      // Gaming
      'PlayStation 5',
      'PlayStation 5 Digital Edition',
      'Xbox Series X',
      'Xbox Series S',
      'Nintendo Switch',
      'Nintendo Switch OLED',
      'Steam Deck OLED',
      'ASUS ROG Ally',
      'Lenovo Legion Go',
      'PS5 DualSense Controller',
      'Xbox Elite Controller Series 2',
      'Nintendo Switch Pro Controller',
      'Oculus Quest 3',
      'PlayStation VR2',
    ],

    // ===== FOOD & BEVERAGES =====
    'Food & Beverages': [
      // Fruits
      'Apples',
      'Bananas',
      'Oranges',
      'Mangoes',
      'Grapes',
      'Watermelon',
      'Cantaloupe',
      'Strawberries',
      'Pineapple',
      'Kiwi Fruit',
      'Peaches',
      'Plums',
      'Cherries',
      'Pears',
      'Apricots',
      'Dates',
      'Pomegranates',
      
      // Vegetables
      'Tomatoes',
      'Potatoes',
      'Onions',
      'Garlic',
      'Ginger',
      'Carrots',
      'Cucumbers',
      'Bell Peppers',
      'Spinach',
      'Lettuce',
      'Broccoli',
      'Cauliflower',
      'Cabbage',
      'Eggplant',
      'Zucchini',
      'Okra',
      'Green Beans',
      'Peas',
      'Corn',
      'Mushrooms',
      
      // Beverages
      'Pepsi',
      'Coca-Cola',
      'Sprite',
      'Fanta',
      '7UP',
      'Mountain Dew',
      'Red Bull',
      'Monster Energy',
      'Mineral Water',
      'Orange Juice',
      'Apple Juice',
      'Mango Juice',
      'Mixed Fruit Juice',
      'Rooh Afza',
      
      // Dairy
      'Fresh Milk',
      'Yogurt',
      'Butter',
      'Cheese',
      'Cream',
      'Ice Cream',
      'Buttermilk',
      'Lassi',
      'Paneer',
      'Ghee',
      
      // Breads/Bakery
      'White Bread',
      'Brown Bread',
      'Whole Wheat Bread',
      'Naan',
      'Roti',
      'Paratha',
      'Burger Bun',
      'Hot Dog Bun',
      'Croissant',
      'Pita Bread',
      'Bagel',
      'Muffin',
      'Cake',
      
      // Snacks
      'Lays Chips',
      'Kurkure',
      'Cheetos',
      'Pringles',
      'Doritos',
      'Popcorn',
      'Dairy Milk Chocolate',
      'KitKat',
      'Oreo Cookies',
      'Chips Ahoy',
      'Digestive Biscuits',
      'Marie Biscuits',
      
      // Rice/Pulses
      'Basmati Rice',
      'Brown Rice',
      'White Rice',
      'Chana Dal',
      'Moong Dal',
      'Masoor Dal',
      'Toor Dal',
      'Urad Dal',
      'Kidney Beans',
      'Chickpeas',
      'Lentils',
      'Quinoa',
      'Oats',
      'Wheat Flour',
      
      // Oils/Spices
      'Cooking Oil',
      'Olive Oil',
      'Table Salt',
      'Black Pepper',
      'Cumin Seeds',
      'Coriander Powder',
      'Turmeric Powder',
      'Red Chili Powder',
      'Garam Masala',
      'Mango Pickle',
      'Mixed Pickle',
      'Lemon Pickle',
      'Soy Sauce',
    ],

    // ===== CLOTHING =====
    'Clothing': [
      // Men's T-Shirts
      'Cotton T-Shirt White',
      'Cotton T-Shirt Black',
      'Cotton T-Shirt Navy',
      'Polo T-Shirt White',
      'Polo T-Shirt Black',
      'V-Neck T-Shirt Gray',
      'V-Neck T-Shirt Blue',
      'Graphic T-Shirt',
      'Striped T-Shirt',
      
      // Men's Shirts
      'Formal Shirt White',
      'Formal Shirt Blue',
      'Casual Shirt Checkered',
      'Linen Shirt Beige',
      'Oxford Shirt Blue',
      'Denim Shirt Blue',
      'Flannel Shirt Red',
      
      // Men's Jeans
      'Slim Fit Jeans Blue',
      'Slim Fit Jeans Black',
      'Regular Fit Jeans Blue',
      'Straight Cut Jeans',
      'Distressed Jeans',
      'Skinny Jeans Black',
      'Bootcut Jeans',
      
      // Women's Tops
      'Cotton Top White',
      'Cotton Top Black',
      'Silk Blouse',
      'Tunic Blue',
      'Tunic Red',
      'Peplum Top Pink',
      'Off-Shoulder Top',
      'Wrap Top Floral',
      
      // Women's Dresses
      'Maxi Dress Floral',
      'Midi Dress Striped',
      'Mini Dress Black',
      'A-Line Dress Blue',
      'Bodycon Dress Red',
      'Wrap Dress Floral',
      
      // Women's Jeans
      'Skinny Jeans Blue',
      'Skinny Jeans Black',
      'Boyfriend Jeans Blue',
      'Flared Jeans',
      'High-Waist Jeans',
      'Jeggings Black',
      'Mom Jeans',
      
      // Kids Clothing
      'Kids T-Shirt Red',
      'Kids T-Shirt Blue',
      'Kids Dress Pink',
      'Kids Jeans Blue',
      'Kids Joggers Gray',
      'Kids Sweater Green',
      'Kids Jacket Red',
      'Kids Pajama Set',
      'School Uniform',
      
      // Traditional
      'White Kurta',
      'Blue Kurta',
      'Shalwar Kameez White',
      'Shalwar Kameez Blue',
      'Chiffon Dupatta',
      'Silk Dupatta',
      'Black Waistcoat',
      'Gold Sherwani',
      'Red Lehenga',
    ],

    // ===== BOOKS =====
    'Books': [
      // Fiction
      'The Alchemist',
      'The Da Vinci Code',
      'The Kite Runner',
      'Pride and Prejudice',
      'Animal Farm',
      '1984',
      'The Great Gatsby',
      'Wuthering Heights',
      'Jane Eyre',
      'Frankenstein',
      'Moby Dick',
      'The Catcher in the Rye',
      'The Hobbit',
      'The Lord of the Rings',
      'Harry Potter Series',
      'The Hunger Games',
      'The Fault in Our Stars',
      'The Picture of Dorian Gray',
      
      // Non-Fiction
      'The Power of Habit',
      'Sapiens',
      'A Brief History of Time',
      'The Art of War',
      'The 48 Laws of Power',
      'Atomic Habits',
      'The Psychology of Money',
      'Rich Dad Poor Dad',
      'The 7 Habits of Highly Effective People',
      'How to Win Friends and Influence People',
      
      // Science
      'Cosmos',
      'The Double Helix',
      'The Selfish Gene',
      'The Elegant Universe',
      'The God Delusion',
      'The Origin of Species',
      'Astrophysics for People in a Hurry',
      
      // Business
      'The Lean Startup',
      'Zero to One',
      'Good to Great',
      'The Innovator\'s Dilemma',
      'Thinking, Fast and Slow',
      'Start with Why',
      
      // Urdu Books
      'Pir-e-Kamil',
      'Raja Gidh',
      'Basti',
      'Udas Naslain',
      'Manto Ke Afsanay',
      'Mirat-ul-Uroos',
      
      // Poetry
      'Shakespeare Sonnets',
      'Allama Iqbal Poetry',
      'Faiz Ahmed Faiz Poetry',
      'Mirza Ghalib Poetry',
      'Rumi Poetry',
      'Maya Angelou Poetry',
      
      // Children Books
      'The Very Hungry Caterpillar',
      'Goodnight Moon',
      'Where the Wild Things Are',
      'Charlotte\'s Web',
      'Matilda',
      'Charlie and the Chocolate Factory',
      'The Giving Tree',
      'Alice in Wonderland',
    ],

    // ===== BEAUTY & HEALTH =====
    'Beauty & Health': [
      // Skincare
      'Face Wash',
      'Face Cream',
      'Face Serum',
      'Sunscreen SPF 30',
      'Sunscreen SPF 50',
      'Moisturizer',
      'Toners',
      'Face Mask',
      'Eye Cream',
      'Lip Balm',
      
      // Hair Care
      'Shampoo',
      'Conditioner',
      'Hair Oil',
      'Hair Serum',
      'Hair Mask',
      'Anti-Dandruff Shampoo',
      'Hair Color',
      'Hair Spray',
      
      // Makeup
      'Foundation',
      'Concealer',
      'Powder',
      'Blush',
      'Mascara',
      'Eyeliner',
      'Lipstick',
      'Lip Gloss',
      'Nail Polish',
      
      // Personal Care
      'Soap',
      'Body Wash',
      'Deodorant',
      'Perfume',
      'Hand Cream',
      'Body Lotion',
      'Shaving Cream',
      'Razor',
      
      // Oral Care
      'Toothpaste',
      'Toothbrush',
      'Mouthwash',
      'Dental Floss',
      'Whitening Strips',
    ],

    // ===== AUTOMOTIVE =====
    'Automotive': [
      // Engine Parts
      'Engine Oil 5W30',
      'Engine Oil 10W40',
      'Engine Coolant',
      'Air Filter',
      'Oil Filter',
      'Fuel Filter',
      'Spark Plugs',
      
      // Brakes
      'Brake Pads',
      'Brake Discs',
      'Brake Fluid',
      'Brake Caliper',
      
      // Tires
      'Car Tire 16"',
      'Car Tire 17"',
      'All-Season Tire',
      'Winter Tire',
      'Spare Tire',
      
      // Accessories
      'Car Battery',
      'Car Key',
      'Car Cover',
      'Floor Mats',
      'Car Charger',
      'Phone Holder',
      'Car Stereo',
      'Speakers',
      'GPS Navigator',
      
      // Interior
      'Steering Wheel Cover',
      'Seat Covers',
      'Dashboard Camera',
      'Air Freshener',
      'Car Polish',
      'Car Wax',
      
      // Maintenance
      'Windshield Wash',
      'Antifreeze',
      'Transmission Fluid',
      'Power Steering Fluid',
    ],
  };

  // Helper methods
  static List<String> getProductsByCategory(String category) {
    return productNamesByCategory[category] ?? [];
  }

  static List<String> searchProducts({
    required String query,
    String? category,
    int limit = 10,
  }) {
    if (query.isEmpty) return [];

    final searchTerm = query.toLowerCase().trim();
    final List<String> results = [];

    final categories = category != null 
        ? {category: productNamesByCategory[category] ?? []}
        : productNamesByCategory;

    categories.forEach((cat, products) {
      for (var product in products) {
        if (product.toLowerCase().contains(searchTerm)) {
          results.add(product);
        }
      }
    });

    results.sort((a, b) {
      final aLower = a.toLowerCase();
      final bLower = b.toLowerCase();
      
      if (aLower == searchTerm && bLower != searchTerm) return -1;
      if (bLower == searchTerm && aLower != searchTerm) return 1;
      if (aLower.startsWith(searchTerm) && !bLower.startsWith(searchTerm)) return -1;
      if (bLower.startsWith(searchTerm) && !aLower.startsWith(searchTerm)) return 1;
      return a.compareTo(b);
    });

    return results.take(limit).toList();
  }

  static List<String> getCategories() {
    return productNamesByCategory.keys.toList();
  }

  static int getProductCountByCategory(String category) {
    return productNamesByCategory[category]?.length ?? 0;
  }
}