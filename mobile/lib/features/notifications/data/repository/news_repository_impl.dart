
import 'package:dartz/dartz.dart';

import '../../../../core/constans/urls.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/repository/news_repository.dart';
import '../models/news_model.dart';

class NewsRepositoryImpl implements NewsRepository {
  final ApiClient _apiClient;

  NewsRepositoryImpl(this._apiClient);

  @override
  Future<Either<Failure, NewsResponseModel>> getNewsList({int page = 1, int pageSize = 20}) async {
    final response = await _apiClient.get(
      "${MainUrls.notificationsList}?page=$page&page_size=$pageSize",
    );
    if (response.isSuccess) {
      try {
        final newsResponse = NewsResponseModel.fromJson(response.response);
        return Right(newsResponse);
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }

  @override
  Future<Either<Failure, NewsModel>> getNewsById(int id) async {
    final response = await _apiClient.get("${MainUrls.newsRetrieve}$id/retrieve/");
    if (response.isSuccess) {
      try {
        final news = NewsModel.fromJson(response.response);
        return Right(news);
      } catch (e) {
        logger.e("Parsing Error: $e");
        return Left(Failure(error: "Parsing Error: $e", statusCode: response.code));
      }
    }
    return Left(Failure(error: response.response.toString(), statusCode: response.code));
  }
}
