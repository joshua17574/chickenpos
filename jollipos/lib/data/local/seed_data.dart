import '../../core/constants/app_constants.dart';
import '../../core/utils/pin_hasher.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/enums.dart';
import '../../domain/entities/modifier.dart';
import '../../domain/entities/product.dart';
import '../../domain/entities/user.dart';
import 'database.dart';

/// First-run seed: categories, modifier groups, ~26 menu items, default users.
/// Prices are in centavos (₱1.00 = 100).
abstract class SeedData {
  static const catChicken = 'cat_chicken';
  static const catBurgers = 'cat_burgers';
  static const catPasta = 'cat_pasta';
  static const catRice = 'cat_rice';
  static const catSides = 'cat_sides';
  static const catDesserts = 'cat_desserts';
  static const catDrinks = 'cat_drinks';
  static const catCombos = 'cat_combos';

  static const grpSize = 'grp_size';
  static const grpDrink = 'grp_drink';
  static const grpSpice = 'grp_spice';
  static const grpRice = 'grp_rice';

  static List<Category> categories() => const [
        Category(id: catChicken, name: 'Fried Chicken', sortOrder: 0, iconName: 'drumstick'),
        Category(id: catBurgers, name: 'Burgers', sortOrder: 1, iconName: 'burger'),
        Category(id: catPasta, name: 'Spaghetti & Pasta', sortOrder: 2, iconName: 'pasta'),
        Category(id: catRice, name: 'Rice Meals', sortOrder: 3, iconName: 'rice'),
        Category(id: catSides, name: 'Sides', sortOrder: 4, iconName: 'fries'),
        Category(id: catDesserts, name: 'Desserts', sortOrder: 5, iconName: 'icecream'),
        Category(id: catDrinks, name: 'Drinks', sortOrder: 6, iconName: 'cup'),
        Category(id: catCombos, name: 'Value Meals', sortOrder: 7, iconName: 'combo'),
      ];

  static List<ModifierGroup> modifierGroups() => const [
        ModifierGroup(
          id: grpSize,
          name: 'Size',
          selection: ModifierSelection.single,
          required: true,
          options: [
            Modifier(id: 'size_reg', name: 'Regular'),
            Modifier(id: 'size_lrg', name: 'Large', priceDeltaCentavos: 2500),
          ],
        ),
        ModifierGroup(
          id: grpDrink,
          name: 'Drink',
          selection: ModifierSelection.single,
          required: true,
          options: [
            Modifier(id: 'drk_coke', name: 'Coke'),
            Modifier(id: 'drk_sprite', name: 'Sprite'),
            Modifier(id: 'drk_tea', name: 'Iced Tea', priceDeltaCentavos: 1000),
            Modifier(id: 'drk_pine', name: 'Pineapple Juice', priceDeltaCentavos: 1500),
          ],
        ),
        ModifierGroup(
          id: grpSpice,
          name: 'Spice Level',
          selection: ModifierSelection.single,
          required: true,
          options: [
            Modifier(id: 'spc_reg', name: 'Classic'),
            Modifier(id: 'spc_hot', name: 'Spicy'),
          ],
        ),
        ModifierGroup(
          id: grpRice,
          name: 'Add-ons',
          selection: ModifierSelection.multiple,
          min: 0,
          max: 3,
          options: [
            Modifier(id: 'add_rice', name: 'Extra Rice', priceDeltaCentavos: 2000),
            Modifier(id: 'add_gravy', name: 'Extra Gravy', priceDeltaCentavos: 1500),
            Modifier(id: 'add_cheese', name: 'Extra Cheese', priceDeltaCentavos: 1500),
          ],
        ),
      ];

  static List<Product> products() => const [
        // Fried Chicken
        Product(id: 'p_chick1', categoryId: catChicken, name: '1-pc Crispy Chicken', basePriceCentavos: 8200, description: 'One piece of our signature crispy fried chicken.', sortOrder: 0, modifierGroupIds: [grpSpice, grpRice]),
        Product(id: 'p_chick2', categoryId: catChicken, name: '2-pc Crispy Chicken', basePriceCentavos: 15500, description: 'Two crispy chicken pieces.', sortOrder: 1, modifierGroupIds: [grpSpice, grpRice]),
        Product(id: 'p_chick6', categoryId: catChicken, name: '6-pc Bucket', basePriceCentavos: 43900, description: 'Six pieces for sharing.', sortOrder: 2, modifierGroupIds: [grpSpice]),
        Product(id: 'p_chickfil', categoryId: catChicken, name: 'Chicken Fillet', basePriceCentavos: 9500, description: 'Boneless breaded fillet.', sortOrder: 3, modifierGroupIds: [grpSpice, grpRice]),
        // Burgers
        Product(id: 'p_burg_classic', categoryId: catBurgers, name: 'Classic Cheeseburger', basePriceCentavos: 6500, description: 'Beef patty, cheese, special sauce.', sortOrder: 0, modifierGroupIds: [grpRice]),
        Product(id: 'p_burg_double', categoryId: catBurgers, name: 'Double Decker', basePriceCentavos: 11900, description: 'Two beef patties, double cheese.', sortOrder: 1, modifierGroupIds: [grpRice]),
        Product(id: 'p_burg_chick', categoryId: catBurgers, name: 'Crispy Chicken Burger', basePriceCentavos: 8900, description: 'Crispy fillet, lettuce, mayo.', sortOrder: 2, modifierGroupIds: [grpSpice]),
        // Pasta
        Product(id: 'p_spag', categoryId: catPasta, name: 'Sweet-Style Spaghetti', basePriceCentavos: 6000, description: 'Sweet sauce, hotdog slices, cheese.', sortOrder: 0),
        Product(id: 'p_spag_lg', categoryId: catPasta, name: 'Spaghetti Family Pan', basePriceCentavos: 22500, description: 'Good for 4-5.', sortOrder: 1),
        Product(id: 'p_carb', categoryId: catPasta, name: 'Creamy Carbonara', basePriceCentavos: 8500, description: 'Creamy white sauce with bacon.', sortOrder: 2),
        // Rice Meals
        Product(id: 'p_rice_chick', categoryId: catRice, name: 'Chicken Rice Meal', basePriceCentavos: 11500, description: '1-pc chicken with rice.', sortOrder: 0, modifierGroupIds: [grpSpice, grpRice]),
        Product(id: 'p_rice_burgsteak', categoryId: catRice, name: 'Burger Steak Rice', basePriceCentavos: 8900, description: 'Beef patties in mushroom gravy.', sortOrder: 1, modifierGroupIds: [grpRice]),
        Product(id: 'p_rice_porkchop', categoryId: catRice, name: 'Pork Chop Rice', basePriceCentavos: 10500, description: 'Fried pork chop with rice.', sortOrder: 2, modifierGroupIds: [grpRice]),
        Product(id: 'p_rice_bangus', categoryId: catRice, name: 'Bangus Belly Rice', basePriceCentavos: 11900, description: 'Marinated milkfish belly.', sortOrder: 3, modifierGroupIds: [grpRice]),
        // Sides
        Product(id: 'p_fries', categoryId: catSides, name: 'Fries', basePriceCentavos: 5500, description: 'Golden crispy fries.', sortOrder: 0, modifierGroupIds: [grpSize]),
        Product(id: 'p_mash', categoryId: catSides, name: 'Mashed Potato', basePriceCentavos: 4500, description: 'With savory gravy.', sortOrder: 1),
        Product(id: 'p_corn', categoryId: catSides, name: 'Buttered Corn', basePriceCentavos: 4000, description: 'Sweet corn kernels.', sortOrder: 2),
        Product(id: 'p_nuggets', categoryId: catSides, name: 'Chicken Nuggets (6pc)', basePriceCentavos: 7500, description: 'With dip.', sortOrder: 3),
        // Desserts
        Product(id: 'p_sundae', categoryId: catDesserts, name: 'Choco Sundae', basePriceCentavos: 3900, description: 'Soft-serve with chocolate syrup.', sortOrder: 0),
        Product(id: 'p_peachpie', categoryId: catDesserts, name: 'Peach Mango Pie', basePriceCentavos: 3500, description: 'Crispy crust, fruit filling.', sortOrder: 1),
        Product(id: 'p_float', categoryId: catDesserts, name: 'Coke Float', basePriceCentavos: 4500, description: 'Coke with soft-serve.', sortOrder: 2),
        // Drinks
        Product(id: 'p_coke', categoryId: catDrinks, name: 'Coke', basePriceCentavos: 3500, description: 'Ice-cold.', sortOrder: 0, modifierGroupIds: [grpSize]),
        Product(id: 'p_tea', categoryId: catDrinks, name: 'Iced Tea', basePriceCentavos: 3900, description: 'House-brewed.', sortOrder: 1, modifierGroupIds: [grpSize]),
        Product(id: 'p_water', categoryId: catDrinks, name: 'Bottled Water', basePriceCentavos: 2500, description: '500ml.', sortOrder: 2),
        // Value Meals (combos)
        Product(id: 'p_combo_chick', categoryId: catCombos, name: 'Chicken + Spaghetti Combo', basePriceCentavos: 15900, description: '1-pc chicken, spaghetti, drink.', isCombo: true, sortOrder: 0, modifierGroupIds: [grpSpice, grpDrink]),
        Product(id: 'p_combo_burg', categoryId: catCombos, name: 'Burger Meal Combo', basePriceCentavos: 12900, description: 'Cheeseburger, fries, drink.', isCombo: true, sortOrder: 1, modifierGroupIds: [grpDrink]),
        Product(id: 'p_combo_family', categoryId: catCombos, name: 'Family Feast', basePriceCentavos: 59900, description: '6-pc chicken, family spaghetti, 4 drinks.', isCombo: true, sortOrder: 2, modifierGroupIds: [grpSpice]),
      ];

  static List<User> users() => [
        User(
          id: 'u_admin',
          name: 'Store Manager',
          role: UserRole.admin,
          pinHash: PinHasher.hash(AppConstants.defaultAdminPin),
        ),
        User(
          id: 'u_cashier',
          name: 'Cashier 1',
          role: UserRole.cashier,
          pinHash: PinHasher.hash('0000'),
        ),
      ];

  /// Idempotent: seeds only when the catalog is empty.
  static Future<void> seedIfEmpty(AppDatabase db) async {
    final existing = await db.productDao.getCategories();
    if (existing.isNotEmpty) return;
    for (final c in categories()) {
      await db.productDao.upsertCategory(c);
    }
    for (final g in modifierGroups()) {
      await db.productDao.upsertModifierGroup(g);
    }
    for (final p in products()) {
      await db.productDao.upsertProduct(p);
    }
    for (final u in users()) {
      await db.userDao.upsertUser(u);
    }
  }
}
