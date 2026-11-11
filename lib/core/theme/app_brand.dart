import 'package:flutter/material.dart';

/// Identidade fixa do produto "Painel 24/7". Não muda por Empresa: o
/// white-label troca apenas nome e logo exibidos na barra superior.
///
/// Cores extraídas de `assets/icon/icon.png`.
abstract final class AppBrand {
  static const name = 'Painel 24/7';

  /// Contorno do "24" e cauda das setas azuis.
  static const navy = Color(0xFF0B2A80);

  /// Azul principal do logo; semente do esquema de cores.
  static const blue = Color(0xFF0070D0);

  /// Brilho do "24" e ponta das setas azuis.
  static const blueLight = Color(0xFF3088E0);

  /// Contorno do "7" e cauda das setas laranja.
  static const red = Color(0xFFF84000);

  /// Laranja principal: cor de destaque da marca.
  static const orange = Color(0xFFF87000);

  /// Ponta das setas laranja e brilho do "7".
  static const yellow = Color(0xFFF8B810);

  /// Título de marca: o peso e a inclinação do "24/7" do logo. Só para
  /// títulos de telas de entrada (login, onboarding, 404), não para conteúdo.
  static TextStyle? display(TextStyle? base) => base?.copyWith(
    fontWeight: FontWeight.w800,
    fontStyle: FontStyle.italic,
    letterSpacing: -.5,
  );

  /// Cauda → ponta, no sentido do movimento das setas.
  static const blueSweep = [navy, blue, blueLight];
  static const orangeSweep = [red, orange, yellow];

  static const blueGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [blueLight, blue],
  );

  static const orangeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [yellow, orange],
  );
}
