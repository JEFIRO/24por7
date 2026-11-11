import 'package:app_24por7/core/theme/app_theme.dart';
import 'package:app_24por7/src/model/api_client.dart';
import 'package:app_24por7/src/model/operational_repository.dart';
import 'package:app_24por7/src/page/onboarding_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeRepository extends OperationalRepository {
  Map<String, dynamic>? sent;
  (String, String)? paired;

  @override
  Future<TerminalAdmin> parearTerminal(String id, String code) async {
    paired = (id, code);
    throw const ApiException('x', 409, 'PAIRING_CODE_INVALID');
  }

  @override
  Future<Map<String, dynamic>> onboarding(Map<String, dynamic> payload) async {
    sent = payload;
    return {'terminalId': 't1'};
  }
}

void main() {
  late _FakeRepository repository;
  final logins = <(String, String)>[];

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    repository = _FakeRepository();
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: OnboardingPage(
          repository: repository,
          login: (cpf, senha) async => logins.add((cpf, senha)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester, Map<String, String> values) async {
    for (final entry in values.entries) {
      await tester.enterText(
        find.byKey(Key('onboarding-${entry.key}')),
        entry.value,
      );
    }
    await tester.pump();
  }

  Future<void> next(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('onboarding-next')));
    await tester.pumpAndSettle();
  }

  testWidgets('não avança com campo obrigatório vazio ou CPF incompleto', (
    tester,
  ) async {
    await pump(tester);
    await next(tester);
    expect(find.text('Como você se chama?'), findsOneWidget);
    expect(find.text('Preencha este campo'), findsNWidgets(2));

    await fill(tester, {'gestorNome': 'Ana', 'gestorSobrenome': 'Silva'});
    await next(tester);
    expect(find.text('Seus documentos'), findsOneWidget);

    await fill(tester, {
      'gestorCpf': '1234567',
      'gestorNascimento': '31022000',
    });
    await next(tester);
    expect(find.text('O CPF tem 11 números'), findsOneWidget);
    expect(find.text('Digite uma data válida'), findsOneWidget);
  });

  testWidgets('percorre as etapas, revisa e envia o cadastro completo', (
    tester,
  ) async {
    await pump(tester);
    await fill(tester, {'gestorNome': 'Ana', 'gestorSobrenome': 'Silva'});
    await next(tester);
    await fill(tester, {
      'gestorCpf': '12345678901',
      'gestorNascimento': '05031990',
    });
    expect(find.text('123.456.789-01'), findsOneWidget);
    expect(find.text('05/03/1990'), findsOneWidget);
    await next(tester);
    await fill(tester, {'gestorEmail': 'ana@x.com'});
    await next(tester);
    await fill(tester, {'gestorSenha': 'segredo123'});
    await next(tester);
    await fill(tester, {
      'empresaCnpj': '12345678000199',
      'razaoSocial': 'Mercado Bom LTDA',
      'nomeFantasia': 'Mercado Bom',
    });
    await next(tester);
    await fill(tester, {
      'empresaEmail': 'contato@bom.com',
      'empresaTelefone': '11912345678',
    });
    await next(tester);
    await fill(tester, {
      'cep': '01310100',
      'numero': '1000',
      'logradouro': 'Av. Paulista',
      'bairro': 'Bela Vista',
      'cidade': 'São Paulo',
      'estado': 'sp',
    });
    await next(tester);
    await fill(tester, {'condominioNome': 'Residencial Um'});
    await next(tester);
    await fill(tester, {
      'terminalNome': 'Portaria',
      'terminalCodigo': 'app247-pair:ab12cd34',
    });
    await next(tester);

    expect(find.text('Tudo certo?'), findsOneWidget);
    expect(find.text('Ana Silva'), findsOneWidget);
    expect(find.text('Mercado Bom'), findsOneWidget);

    // Corrigir um item volta à etapa dele com o valor preservado.
    await tester.tap(find.byKey(const Key('onboarding-review-7')));
    await tester.pumpAndSettle();
    expect(find.text('Seu primeiro condomínio'), findsOneWidget);
    expect(find.text('Residencial Um'), findsOneWidget);
    await next(tester);
    await next(tester);

    await next(tester);
    final sent = repository.sent!;
    expect(sent['gestor']['cpf'], '12345678901');
    // O back lê a data em dd/MM/yyyy.
    expect(sent['gestor']['dataNascimento'], '05/03/1990');
    expect(sent['gestor']['roleUser'], 'ADMIN');
    expect(sent['empresa']['cnpj'], '12345678000199');
    expect(sent['empresa']['telefone'], '11912345678');
    expect(sent['empresa']['cep'], '01310100');
    expect(sent['empresa']['estado'], 'SP');
    expect(sent['condominio']['endereco']['rua'], 'Av. Paulista');
    expect(sent['terminal']['nome'], 'Portaria');
    expect(find.text('Cadastro concluído'), findsOneWidget);

    // Com código, entra como o gestor novo e tenta parear o Terminal criado.
    expect(logins.last, ('12345678901', 'segredo123'));
    expect(repository.paired, ('t1', 'AB12-CD34'));
    expect(find.textContaining('O Terminal não foi pareado'), findsOneWidget);
  });
}
