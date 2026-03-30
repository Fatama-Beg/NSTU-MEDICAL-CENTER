import 'package:serverpod/serverpod.dart';

class RouteRoot extends WidgetRoute {
  @override
  Future<WebWidget> build(Session session, Request request) async {
    return TemplateWidget(
      name: 'index', // matches a template in web/templates/index.html if you have static web
      values: {
        'message': 'Hello from Serverpod 3!',
      },
    );
  }
}
