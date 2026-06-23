# Snippet à ajouter dans src/function_http/process_batch/__init__.py
# pour simuler le bug "memory pressure" lors de la démo

# AVANT cette ligne :
#     processed_rows = rows

# AJOUTER ce code :
    if rows > 50000:
        raise RuntimeError("memory pressure detected on large batch")

# Le code complet devient :
#     if rows > 50000:
#         raise RuntimeError("memory pressure detected on large batch")
#     
#     processed_rows = rows
