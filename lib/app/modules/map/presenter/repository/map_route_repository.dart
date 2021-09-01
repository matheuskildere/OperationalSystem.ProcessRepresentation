import 'package:dartz/dartz.dart';
import 'package:feelps/app/core/entities/service_entity.dart';
import 'package:feelps/app/core/enum/status_enum.dart';
import 'package:feelps/app/core/errors/failure.dart';
import 'package:feelps/app/core/flavors/app_flavors.dart';
import 'package:feelps/app/core/services/connectivity_service.dart';
import 'package:feelps/app/core/utils/data_parser.dart';
import 'package:feelps/app/modules/historic/models/service_model.dart';
import 'package:feelps/app/modules/home/models/change_status_request.dart';
import 'package:feelps/app/modules/map/errors/map_error.dart';
import 'package:feelps/app/modules/map/models/status_update_model.dart';
import 'package:firebase_database/firebase_database.dart';

abstract class IMapRouteRepository {
  Future<Either<Failure, ServiceEntity>> getService(
      {required String serviceId});
  Future<Either<Failure, ServiceEntity>> updateStatus(
      {required StatusUpdateModel request});
}

class MapRouteRepository implements IMapRouteRepository {
  final FirebaseDatabase _database;
  final ConnectivityService _connectivityService;
  final String tableName = 'service-${appFlavor!.title}';

  MapRouteRepository(this._database, this._connectivityService);

  @override
  Future<Either<Failure, ServiceEntity>> getService(
      {required String serviceId}) async {
    final result = await _connectivityService.isOnline;
    if (result.isLeft()) {
      return result.fold((l) {
        return Left(l);
      }, (r) {
        return Left(NoConnectionError(
            title: "Atenção",
            message: "Você não possui conexão com a internet!"));
      });
    }
    final reference = _database.reference();

    await reference
        .child(tableName)
        .child(serviceId)
        .update({'status': 'Aceito'});

    await reference
        .child(tableName)
        .child(serviceId)
        .update({'status': 'A caminho da retirada'});

    final snapshotService =
        await reference.child(tableName).child(serviceId).once();
    if (snapshotService.value == null) {
      return Left(GetDirectionsInfoError(
          title: "Não foi possível continuar",
          message: 'Ocorreu um erro ao buscar os dados deste serviço!'));
    }
    final snapMap = Map<String, dynamic>.from(snapshotService.value as Map);
    var service = ServiceModel.fromMap(snapMap);
    service = service.copyWith(status: DeliveryStatusEnum.wayToPickup);
    return Right(service);
  }

  @override
  Future<Either<Failure, ServiceEntity>> updateStatus(
      {required StatusUpdateModel request}) async {
    final result = await _connectivityService.isOnline;
    if (result.isLeft()) {
      return result.fold((l) {
        return Left(l);
      }, (r) {
        return Left(NoConnectionError(
            title: "Atenção",
            message: "Você não possui conexão com a internet!"));
      });
    }
    final reference = _database.reference();

    if (request.observation != null) {
      final snapService =
          await reference.child(tableName).child(request.serviceId).once();
      if (snapService.value['observations'] != null) {
        await reference.child(tableName).child(request.serviceId).update({
          'status': request.status,
          'observations': [
            {
              'createdAt': DateParser.getDateStringEn(DateTime.now()),
              'description': request.observation,
              'status': request.status
            },
            ...snapService.value['observations']
          ]
        });
      } else {
        await reference.child(tableName).child(request.serviceId).update({
          'status': request.status,
          'observations': [
            {
              'createdAt': DateParser.getDateStringEn(DateTime.now()),
              'description': request.observation,
              'status': request.status
            }
          ]
        });
      }
    } else {
      await reference
          .child(tableName)
          .child(request.serviceId)
          .update({'status': request.status});
    }
    final snapshotService =
        await reference.child(tableName).child(request.serviceId).once();
    if (snapshotService.value == null) {
      return Left(GetDirectionsInfoError(
          title: "Não foi possível continuar",
          message: 'Ocorreu um erro ao buscar os dados deste serviço!'));
    }
    final snapMap = Map<String, dynamic>.from(snapshotService.value as Map);
    final service = ServiceModel.fromMap(snapMap);

    return Right(service);
  }
}
