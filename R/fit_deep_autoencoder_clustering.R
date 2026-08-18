#' Learn a nonlinear autoencoder embedding and cluster it with K-means
#' @param matrix Series-by-feature matrix.
#' @param k Number of clusters.
#' @param seed Random seed.
#' @param latent_dimensions Size of the learned embedding.
#' @param epochs Autoencoder training epochs.
#' @return Standardized learned-representation clustering result.
fit_deep_autoencoder_clustering <- function(matrix, k, seed = 4107L,
                                            latent_dimensions = 4L, epochs = 80L) {
  if (!requireNamespace("torch", quietly = TRUE) || !torch::torch_is_installed()) {
    stop("Package 'torch' and its CPU runtime are required for deep clustering.")
  }
  torch::torch_manual_seed(seed)
  input_dimensions <- ncol(matrix)
  latent_dimensions <- max(2L, min(as.integer(latent_dimensions), input_dimensions - 1L))
  hidden_dimensions <- max(latent_dimensions * 2L, min(64L, ceiling(input_dimensions / 2)))

  autoencoder <- torch::nn_module(
    initialize = function() {
      self$encoder <- torch::nn_sequential(
        torch::nn_linear(input_dimensions, hidden_dimensions), torch::nn_relu(),
        torch::nn_linear(hidden_dimensions, latent_dimensions)
      )
      self$decoder <- torch::nn_sequential(
        torch::nn_linear(latent_dimensions, hidden_dimensions), torch::nn_relu(),
        torch::nn_linear(hidden_dimensions, input_dimensions)
      )
    },
    forward = function(x) self$decoder(self$encoder(x))
  )
  model <- autoencoder()
  optimizer <- torch::optim_adam(model$parameters, lr = 0.01)
  tensor <- torch::torch_tensor(unname(matrix), dtype = torch::torch_float())

  loss_history <- numeric(as.integer(epochs))
  for (epoch in seq_len(as.integer(epochs))) {
    optimizer$zero_grad()
    reconstruction <- model(tensor)
    loss <- torch::nnf_mse_loss(reconstruction, tensor)
    loss$backward()
    optimizer$step()
    loss_history[epoch] <- as.numeric(loss$item())
  }
  model$eval()
  embedding <- as.matrix(as.array(model$encoder(tensor)$detach()))
  reconstruction <- as.matrix(as.array(model(tensor)$detach()))
  rownames(reconstruction) <- rownames(matrix)
  rownames(embedding) <- rownames(matrix)
  set.seed(seed)
  partition <- stats::kmeans(embedding, centers = k, nstart = 50, iter.max = 200)
  clusters <- partition$cluster
  names(clusters) <- rownames(matrix)
  list(
    cluster = clusters,
    prototypes = calculate_cluster_prototypes(matrix, clusters),
    model = model,
    embedding = embedding,
    distance_matrix = stats::dist(embedding),
    reconstruction_loss = as.numeric(loss$item()),
    reconstruction = reconstruction,
    reconstruction_error = rowMeans((matrix - reconstruction)^2),
    loss_history = loss_history,
    algorithm = "deep_autoencoder",
    distance = "latent_euclidean"
  )
}
