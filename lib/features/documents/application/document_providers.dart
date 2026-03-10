import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/application/providers.dart';
import '../domain/models/document.dart';
import '../infrastructure/document_repository.dart';

/// Document repository provider
final documentRepositoryProvider = Provider<DocumentRepository>((ref) {
  final dioClient = ref.watch(dioClientProvider);
  return DocumentRepository(dioClient: dioClient);
});

/// Document state
sealed class DocumentState {
  const DocumentState();
}

class DocumentInitial extends DocumentState {
  const DocumentInitial();
}

class DocumentLoading extends DocumentState {
  const DocumentLoading();
}

class DocumentLoaded extends DocumentState {
  final List<DriverDocument> documents;
  const DocumentLoaded(this.documents);
}

class DocumentError extends DocumentState {
  final String message;
  const DocumentError(this.message);
}

class DocumentUploading extends DocumentState {
  final List<DriverDocument> documents;
  final double progress;
  const DocumentUploading(this.documents, this.progress);
}

/// Document notifier
class DocumentNotifier extends StateNotifier<DocumentState> {
  final DocumentRepository _repository;

  DocumentNotifier({required DocumentRepository repository})
      : _repository = repository,
        super(const DocumentInitial());

  /// Load documents from API
  Future<void> loadDocuments() async {
    state = const DocumentLoading();

    try {
      final documents = await _repository.getDocuments();
      state = DocumentLoaded(documents);
    } catch (e) {
      state = DocumentError(_parseError(e));
    }
  }

  /// Upload a new document
  Future<bool> uploadDocument({
    required DocumentUploadRequest request,
    required Uint8List fileBytes,
    required String fileName,
    required String contentType,
  }) async {
    final currentState = state;
    final currentDocuments = currentState is DocumentLoaded
        ? currentState.documents
        : currentState is DocumentUploading
            ? currentState.documents
            : <DriverDocument>[];

    state = DocumentUploading(currentDocuments, 0.0);

    try {
      // Repository handles the full 3-step flow:
      // 1. Get presigned URL from backend
      // 2. Upload file to S3
      // 3. Create document record in database
      final newDocument = await _repository.uploadDocument(
        request: request,
        fileBytes: fileBytes,
        fileName: fileName,
        contentType: contentType,
        onProgress: (progress) {
          state = DocumentUploading(currentDocuments, progress);
        },
      );

      state = DocumentLoaded([...currentDocuments, newDocument]);
      return true;
    } catch (e) {
      state = DocumentError(_parseError(e));
      return false;
    }
  }

  /// Delete a document
  Future<bool> deleteDocument(String documentId) async {
    final currentState = state;
    if (currentState is! DocumentLoaded) return false;

    try {
      await _repository.deleteDocument(documentId);
      final updatedDocuments = currentState.documents
          .where((d) => d.documentId != documentId)
          .toList();
      state = DocumentLoaded(updatedDocuments);
      return true;
    } catch (e) {
      state = DocumentError(_parseError(e));
      return false;
    }
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceAll('Exception: ', '');
    }
    return 'An error occurred. Please try again.';
  }
}

/// Document state provider
final documentStateProvider =
    StateNotifierProvider<DocumentNotifier, DocumentState>((ref) {
  final repository = ref.watch(documentRepositoryProvider);
  return DocumentNotifier(repository: repository);
});

/// Convenience provider for document list
final documentListProvider = Provider<List<DriverDocument>>((ref) {
  final state = ref.watch(documentStateProvider);
  if (state is DocumentLoaded) return state.documents;
  if (state is DocumentUploading) return state.documents;
  return [];
});

/// Provider for driver documents only
final driverDocumentsProvider = Provider<List<DriverDocument>>((ref) {
  return ref
      .watch(documentListProvider)
      .where((d) => d.belongsTo == 'driver')
      .toList();
});

/// Provider for vehicle documents only
final vehicleDocumentsProvider = Provider<List<DriverDocument>>((ref) {
  return ref
      .watch(documentListProvider)
      .where((d) => d.belongsTo == 'vehicle')
      .toList();
});

/// Provider for documents with issues (expired or expiring)
final documentsWithIssuesProvider = Provider<List<DriverDocument>>((ref) {
  return ref
      .watch(documentListProvider)
      .where((d) => d.isExpired || d.isExpiringSoon || d.status == DocumentStatus.rejected)
      .toList();
});
