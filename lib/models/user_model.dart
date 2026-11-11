class UserModel {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String? token;
  final Set<String> roles;
  final double balance;
  final int? customerId;
  final String? customerCode;

  const UserModel({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.token,
    this.roles = const {'USER'},
    this.balance = 0.0,
    this.customerId,
    this.customerCode,
  });

  bool get isAdmin => roles.contains('ADMIN');
  bool get isCashier => roles.contains('CASHIER') || isAdmin;
  bool get isUser => roles.contains('USER');

  UserModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? token,
    Set<String>? roles,
    double? balance,
    int? customerId,
    String? customerCode,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      token: token ?? this.token,
      roles: roles ?? this.roles,
      balance: balance ?? this.balance,
      customerId: customerId ?? this.customerId,
      customerCode: customerCode ?? this.customerCode,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rolesList = json['roles'];
    final roles = rolesList is List
        ? rolesList.map((e) => e.toString()).toSet()
        : {'USER'};
    return UserModel(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      token: json['token'] as String?,
      roles: roles,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      customerId: json['customerId'] as int?,
      customerCode: json['customerCode'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'name': name,
        'phone': phone,
        'email': email,
        if (token != null) 'token': token,
        'roles': roles.toList(),
        'balance': balance,
        if (customerId != null) 'customerId': customerId,
        if (customerCode != null) 'customerCode': customerCode,
      };

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email, roles: $roles, balance: $balance)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          phone == other.phone &&
          email == other.email;

  @override
  int get hashCode => Object.hash(id, name, phone, email);
}
