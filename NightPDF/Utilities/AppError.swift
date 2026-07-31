import Foundation

enum AppError: LocalizedError, Equatable {
    case fileUnavailable
    case copyFailed(String)
    case invalidPDF
    case protectedPDF
    case documentMissing
    case storageUnavailable

    var errorDescription: String? {
        switch self {
        case .fileUnavailable:
            return "El archivo no esta disponible."
        case .copyFailed(let detail):
            return "No se pudo copiar el PDF. \(detail)"
        case .invalidPDF:
            return "El archivo no parece ser un PDF valido."
        case .protectedPDF:
            return "El PDF esta protegido con contrasena."
        case .documentMissing:
            return "El documento ya no esta en la biblioteca local."
        case .storageUnavailable:
            return "No se pudo acceder al almacenamiento local."
        }
    }
}

