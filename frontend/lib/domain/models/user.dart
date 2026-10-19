/// Modelo de dominio que representa a un usuario autenticado.
class User {
  const User({
    required this.id,
    required this.nombre,
    required this.email,
    required this.creadoEn,
  });

  final int id;
  final String nombre;
  final String email;
  final DateTime creadoEn;
}
