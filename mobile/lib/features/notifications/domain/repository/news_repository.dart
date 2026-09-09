
import 'package:dartz/dartz.dart';

import '../../../../core/error/failure.dart';
import '../../data/models/news_model.dart';

abstract class NewsRepository {
  Future<Either<Failure, NewsResponseModel>> getNewsList({int page = 1, int pageSize = 20});

  /// Bitta yangilikni/bildirishnomani id bo'yicha olish (push notificationId'dan).
  Future<Either<Failure, NewsModel>> getNewsById(int id);
}
