import '../../core/utils/typedef.dart';
import '../entities/batch.dart';
import '../entities/batch_scan.dart';

abstract class BatchRepository {
  ResultFuture<Batch> createBatch(Batch batch);
  ResultFuture<List<Batch>> getAllBatches();
  ResultFuture<Batch> getBatchById(String id);
  ResultFuture<void> updateBatch(Batch batch);
  ResultFuture<void> deleteBatch(String id);
  
  ResultFuture<BatchScan> saveScan(BatchScan scan);
  ResultFuture<List<BatchScan>> getScansByBatchId(String batchId);
  ResultFuture<BatchScan> getLatestScan(String batchId);
}