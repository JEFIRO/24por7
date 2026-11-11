import 'package:flutter/widgets.dart';

/// Durações e curvas padrão. Toda animação do app sai daqui.
abstract final class AppMotion {
  /// Feedback imediato: hover, troca de ícone, cor de um controle.
  static const fast = Duration(milliseconds: 120);

  /// Padrão: fade de conteúdo, troca de estado, mensagem de erro.
  static const base = Duration(milliseconds: 200);

  /// Entradas e trocas de etapa, onde algo se desloca.
  static const slow = Duration(milliseconds: 350);

  /// Atraso entre itens de uma entrada escalonada.
  static const stagger = Duration(milliseconds: 60);

  /// Quantos itens entram escalonados; o resto aparece junto.
  static const staggerMaxItems = 8;

  /// Uma volta completa das setas do logo.
  static const brandCycle = Duration(milliseconds: 2400);

  /// Volta única das setas no splash de abertura, já com tudo carregado.
  static const splashMin = Duration(milliseconds: 1600);

  /// Uma passada do brilho do skeleton.
  static const shimmer = Duration(milliseconds: 1400);

  /// Elementos que entram ou mudam de valor.
  static const enter = Curves.easeOutCubic;

  /// Elementos que saem.
  static const exit = Curves.easeInCubic;

  /// Movimento que começa e termina na tela.
  static const standard = Curves.easeInOutCubic;

  /// Deslocamento de entrada, em pixels lógicos.
  static const enterOffset = 16.0;

  /// "Reduzir movimento" do sistema. Com ele ligado, nada se desloca nem
  /// gira em loop; trocas de estado viram corte seco.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// [duration], ou zero quando o sistema pede movimento reduzido.
  static Duration of(BuildContext context, Duration duration) =>
      reduced(context) ? Duration.zero : duration;
}
