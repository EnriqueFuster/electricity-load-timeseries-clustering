# Theoretical guide to electricity load-profile clustering

This guide explains the statistical and modelling choices behind the benchmark. It follows the same sequence as the code: define what one observation represents, decide which data are admissible, choose how a load profile is represented, decide what differences between profiles should matter, fit a clustering method, and then check whether the resulting partition is worth interpreting.

The emphasis is on the methods that are actually implemented in this repository. Where a method has an important limitation or the implementation makes a particular assumption, that is stated explicitly. References are collected at the end.

## Acronyms and shorthand

| Term | Full name | Meaning here |
|---|---|---|
| AIC | Akaike Information Criterion | Likelihood-based model comparison with a penalty for model complexity. |
| ARI | Adjusted Rand Index | Agreement between two partitions after correcting for chance. |
| BIC | Bayesian Information Criterion | Fit-versus-complexity criterion; under the `mclust` convention, larger values indicate stronger support. |
| catch22 | 22 CAnonical Time-series CHaracteristics | Compact set of canonical time-series features. |
| catch24 | catch22 plus mean and standard deviation | catch22 with two level-and-scale statistics added back. |
| CLR | Centred log-ratio | Log-ratio transformation for compositional data. |
| DBA | Dynamic Time Warping Barycenter Averaging | Estimator of an average sequence under DTW alignment. |
| DEC | Deep Embedded Clustering | Joint representation-learning and clustering method; not implemented here. |
| DTW | Dynamic Time Warping | Sequence dissimilarity that allows limited temporal alignment. |
| EM | Expectation–maximisation | Iterative procedure commonly used to fit Gaussian mixtures. |
| GMM | Gaussian Mixture Model | Probabilistic model with Gaussian mixture components. |
| HAC | Hierarchical agglomerative clustering | Bottom-up clustering represented by a dendrogram. |
| HDBSCAN | Hierarchical Density-Based Spatial Clustering of Applications with Noise | Density-based clustering that can leave observations unassigned as noise. |
| HMM | Hidden Markov Model | Latent-state sequence model discussed only as a possible extension. |
| IANA | Internet Assigned Numbers Authority | Maintains the canonical timezone database used by common software libraries. |
| KL | Kullback–Leibler | Directional divergence between probability distributions. |
| L1 | L1 norm | Sum of absolute differences; the norm behind Manhattan distance. |
| NCC | Normalised cross-correlation | Shift-aware correlation used to construct SBD. |
| PAA | Piecewise Aggregate Approximation | Time-series representation based on interval averages. |
| PAM | Partitioning Around Medoids | K-medoids algorithm whose cluster representatives are observed data points. |
| PC | Principal component | One orthogonal direction estimated by PCA. |
| PCA | Principal Component Analysis | Linear transformation into orthogonal directions ordered by explained variance. |
| SAX | Symbolic Aggregate approXimation | Symbolic representation of a reduced time series. |
| SBD | Shape-Based Distance | Shift-aware dissimilarity derived from NCC. |
| SOM | Self-Organising Map | Neural mapping method that places similar observations close on a low-dimensional grid. |
| UTC | Coordinated Universal Time | Common time reference used after timestamp parsing. |

## 1. How the benchmark is structured

Clustering starts before an algorithm is fitted. An experiment in this repository can be written as:

```text
research question
  -> unit of analysis
  -> quality policy
  -> representation
  -> normalization
  -> similarity / distance
  -> clustering algorithm
  -> hyperparameters
  -> validation
  -> interpretation
```

These are different modelling decisions and should be treated as such. Dynamic Time Warping (DTW), for example, defines a dissimilarity between two sequences; Principal Component Analysis (PCA) transforms the data; Partitioning Around Medoids (PAM) forms the clusters. Comparing "DTW versus K-means" mixes different levels of the pipeline and does not isolate what caused a change in the result.

A cleaner comparison keeps the representation and algorithm fixed and changes only the distance:

```text
typical week + PAM + Euclidean
typical week + PAM + constrained DTW
```

Before comparing algorithms, define what it means for two electricity consumers to be similar. That decision determines which representation, normalization and distance are appropriate.

## 2. Unit of analysis

### 2.1 Meter-level clustering

The implemented benchmark clusters **meters**, or more precisely one complete profile per accepted meter. Each meter contributes one natural-year history, which is converted into the representation selected for the experiment before clustering.

This setup is intended to recover relatively stable consumption typologies at meter level. It does not imply that every day observed for a given meter follows one fixed daily pattern.

### 2.2 Meter-day clustering

A different study could use individual days as observations. Each meter-year would then be split into 24-hour vectors:

$$
\mathbf{x}_{i,d} = (x_0, x_1, \ldots, x_{23}).
$$

Clusters in that setting would describe recurring daily shapes: morning peaks, evening peaks, double peaks, flat demand, night-intensive profiles, and so on.

That is a different statistical problem from the one implemented here. A single meter would contribute many observations rather than one.

### 2.3 Daily archetypes followed by meter-level clustering

A two-stage design is also possible:

1. Cluster individual 24-hour meter-days.
2. Treat the resulting prototypes as a dictionary of daily archetypes.
3. Describe each meter through its archetype frequencies, entropy, transitions, magnitude, weekday/weekend composition and seasonal composition.
4. Cluster those meter-level fingerprints.

This separates two questions that are otherwise easy to confound: which daily behaviours exist, and how each consumer combines those behaviours over the year.

The approach is not implemented in the current benchmark. It changes the unit of analysis and would need temporal validation designed to avoid leakage between training and evaluation periods.

## 3. Data-quality rules

The web application requires at least one complete January-to-December hourly window for every accepted profile. A natural year contains 8,760 hours, or 8,784 in a leap year. Missingness is assessed before regularization and imputation.

The pipeline records invalid timestamps, duplicate observations, negative values, gaps, missingness and coverage. Once a qualifying year has been identified, that year is aligned to the expected hourly calendar and the permitted missing values are imputed. Imputation comes after the acceptance decision: it is not used to turn an otherwise ineligible profile into an apparently complete one.

The full-year requirement is important for this benchmark because several representations depend on the calendar. A typical week estimated only from winter or summer should not be read as an annual routine, and seasonal summaries are not comparable when some meters cover different parts of the year.

## 4. Implemented representations

A representation determines which parts of the original load curve remain available to the clustering method. No representation is neutral: compressing the data makes some differences easier to model and removes others.

### 4.1 Typical week (`typical_week`)

Each meter is reduced to 168 ordered values:

```text
Monday 00:00 ... Monday 23:00 ... Sunday 23:00
```

For every hour of the week, the pipeline calculates either the configured median or mean across the selected year.

This representation keeps the recurrent weekly pattern in a form that can still be plotted directly and passed to ordered-series methods such as DTW, SBD and Soft-DTW. It distinguishes Monday from Tuesday, weekday from weekend and one hour from the next.

The compression also has clear consequences. Seasonal evolution is averaged away, exceptional days have little influence when the median is used, and the resulting 168 variables are strongly correlated. With a small number of meters, that dimensionality can matter.

### 4.2 Seasonal daypart signature (`seasonal_daypart`)

The annual series is summarized by:

- four meteorological seasons;
- weekday versus weekend;
- six four-hour periods.

A complete profile therefore yields up to `4 × 2 × 6 = 48` named features.

Compared with the older `day_type_hour` summary, this representation retains explicit seasonal information while remaining much smaller than an hourly annual curve. The features also have a physical interpretation: winter weekend evening consumption, summer weekday morning consumption, and so forth.

The price of that compression is temporal detail. A four-hour block can hide a short, sharp peak, and the representation is no longer an ordered sequence on which DTW-style alignment has a meaningful interpretation. The season definition also assumes a Northern Hemisphere calendar.

### 4.3 Behavioural features (`behavioral_features`)

The behavioural representation describes each meter through engineered summaries rather than through a fixed sequence of clock-time values. The implemented features include:

- mean hourly, median daily and 95th-percentile daily consumption;
- load factor;
- hourly and daily coefficients of variation;
- circular encoding of peak time;
- night, morning, daytime, evening and late-night energy shares;
- weekday and weekend mean demand;
- observed seasonal mean demand.

Because these variables use different scales and units, they are standardized feature by feature before clustering.

This representation is useful when the aim is to distinguish interpretable properties such as magnitude, regularity, timing and energy allocation. It is compact enough for methods such as PAM, GMM, HDBSCAN and SOM.

Its limitation is equally straightforward: the model can only use behaviour that has been encoded in the feature set. Several correlated features can also give disproportionate weight to one underlying phenomenon. The feature definitions are modelling choices, not objective properties of the data.

### 4.4 PCA of the typical week (`pca_typical_week`)

For `pca_typical_week`, PCA is applied to the normalized 168-hour weekly matrix. The retained components are the smallest set whose cumulative explained variance reaches the configured target, 95% by default.

PCA reduces the number of variables and removes linear collinearity by expressing the weekly profiles in orthogonal directions. This can make subsequent clustering cheaper and gives the benchmark a direct comparison between the original weekly coordinates and a linear reduced representation.

Explained variance should not be confused with clustering quality. PCA keeps directions with large variance, not directions chosen to separate clusters. Its components also mix information from many hours, so they are harder to interpret physically than the original 168 coordinates.

### 4.5 PCA of the complete annual curve

The annual PCA variants use the full 8,760-hour calendar after removing 29 February from leap years. They differ in what happens before PCA:

| Option | Preparation before PCA | Main question |
|---|---|---|
| `pca_annual_unit_sum` | Divide the 8,760 values by annual energy | How is annual energy distributed across the calendar? |
| `pca_annual_clr` | Unit sum, zero replacement, then CLR | Which hourly shares are high or low relative to the profile's geometric mean? |
| `pca_annual_zscore` | Standardize each meter-year to mean zero and standard deviation one | How does annual shape differ once level and scale are removed? |

PCA then keeps enough components to meet `pca_explained_variance`, subject to `pca_max_components`. The retained dimension is therefore fitted from the data and configuration rather than fixed to an arbitrary number such as 12.

The CLR and z-score variants describe different geometries. A z-score is an affine transformation of the hourly values. CLR first treats the annual curve as a composition whose parts sum to one, then works with log-ratios. In that space, relative allocation matters rather than absolute differences in hourly kWh.

Because the logarithm of zero is undefined, zero shares must be replaced before applying CLR. The implementation uses a configured fraction of the smallest positive share and recloses the row before the transformation.

### 4.6 Canonical time-series features (`catch22` and `catch24`)

`catch22` replaces the original hourly coordinates with 22 time-series characteristics selected from a much larger feature library. They cover aspects of the distribution, autocorrelation, predictability, fluctuation and nonlinear dynamics of a series.

Three variants are implemented:

- `catch22_global` extracts one 22-feature block from the complete year;
- `catch22_seasonal` extracts one block for each season;
- `catch24_seasonal` uses the seasonal catch22 blocks and also includes mean and standard deviation for each season.

The last variant restores two basic level-and-scale statistics that catch22 deliberately leaves out.

All extracted columns are standardized across meters before clustering. These representations can capture temporal behaviour that is difficult to express with a few hand-built load features, but they no longer preserve the original clock-time sequence. DTW and other ordered-series distances therefore do not apply to the feature vectors themselves.

The seasonal versions retain more calendar context than the global feature block, but they also increase dimensionality and may be harder to interpret. They are benchmark alternatives, not presumed improvements.

The two-dimensional PCA plot shown in the application is separate from these representations. It is a diagnostic visualization unless the fitted candidate explicitly uses a PCA representation.

## 5. Normalization

Normalization changes the meaning of similarity. Whether consumption magnitude should matter is a modelling decision, not a preprocessing detail to choose by habit.

### 5.1 Z-score per profile (`zscore`)

$$
z_{it} = \frac{x_{it} - \bar{x}_i}{s_i}.
$$

Each profile is centred on its own mean and scaled by its own standard deviation. The resulting comparison is driven mainly by relative shape. Two meters with very different annual consumption can therefore be close if their normalized weekly patterns are similar.

### 5.2 Unit sum (`unit_sum`)

$$
p_{it} = \frac{x_{it}}{\sum_t x_{it}}.
$$

Each value becomes a share of the profile's total energy. Total consumption is removed, while the distribution of energy through time is retained.

### 5.3 No normalization (`none`)

Without normalization, the original representation values retain both shape and magnitude. For pointwise distances, high-consumption profiles can contribute much larger absolute differences than low-consumption profiles.

That may be undesirable in a shape-oriented study, but it is not inherently wrong. If absolute demand is part of the typology being sought, retaining magnitude can be the correct choice.

Original consumption values are kept for interpretation even when the clustering representation removes magnitude.

## 6. Implemented distances and similarities

### 6.1 Euclidean distance

$$
d(\mathbf{x},\mathbf{y}) =
\sqrt{\sum_j (x_j-y_j)^2}.
$$

Euclidean distance compares matching coordinates directly. In a typical-week representation, 19:00 on one profile is compared with 19:00 on the other. K-means is closely tied to this geometry because its objective minimizes squared Euclidean deviations from cluster centroids.

The distance is fast and easy to interpret, but it has no mechanism for forgiving a small shift in timing.

### 6.2 Manhattan distance

$$
d(\mathbf{x},\mathbf{y}) = \sum_j |x_j-y_j|.
$$

Manhattan distance also compares aligned coordinates, but it sums absolute rather than squared deviations. A single large coordinate difference therefore has less leverage than it does under a squared-error objective.

The repository uses Manhattan dissimilarity with PAM and HDBSCAN in compatible reduced or feature spaces.

### 6.3 Constrained Dynamic Time Warping

DTW compares two ordered sequences while allowing nearby points to be aligned. A peak at 19:00 can, within the permitted window, match a peak at 20:00 instead of being treated as two separate pointwise errors.

The implementation uses a Sakoe-Chiba window to limit the amount of temporal displacement. That constraint matters scientifically: unrestricted warping can make events at meaningfully different times appear similar.

DTW is useful when modest timing variation is expected, but pairwise computation is much more expensive than Euclidean distance. The window size should be treated as part of the experiment rather than as a harmless implementation setting.

### 6.4 Shape-Based Distance (SBD)

SBD derives dissimilarity from normalized cross-correlation. It focuses on the shape of an ordered series and allows phase shifts through the correlation alignment.

It is the native dissimilarity used by k-Shape in this repository and is only used with ordered whole-series inputs.

### 6.5 Soft-DTW

Ordinary DTW chooses the minimum-cost alignment path. Soft-DTW replaces that hard minimum with a smooth approximation controlled by `gamma`. Smaller values approach the ordinary DTW objective.

Uncorrected Soft-DTW is not an ordinary metric: in particular, self-dissimilarity need not be zero. Its values should therefore be interpreted in the context of the fitted recipe rather than read as if they were Euclidean lengths.

### 6.6 Similarity defined by the fitted model

Not every method starts from an explicit distance matrix. A GMM defines groups through fitted probability densities and posterior membership. The autoencoder recipe first learns a latent representation and then uses Euclidean geometry in that learned space.

Those notions of similarity belong to the full model recipe. They should not be confused with Euclidean distance between the original hourly profiles.

## 7. Implemented clustering methods

### 7.1 K-means

K-means alternates between assigning each observation to the nearest arithmetic centroid and recomputing those centroids. Its objective is the within-cluster sum of squared Euclidean deviations.

It is the simplest baseline in the benchmark. K must be specified, initialization can affect the solution, and extreme observations can move the centroid substantially. The method is defined in Euclidean space; replacing its geometry with an arbitrary distance matrix would produce a different algorithm.

### 7.2 PAM / K-medoids

Partitioning Around Medoids chooses observed data points as cluster representatives and minimizes total dissimilarity to those medoids.

Using an observed profile as the representative makes the result easy to inspect and generally makes PAM less sensitive to extremes than a mean-based centroid. More importantly for this benchmark, PAM can use several dissimilarities without changing the clustering algorithm itself. That makes it useful for controlled comparisons between Euclidean, Manhattan and DTW.

The main practical cost is the need to work with pairwise dissimilarities, which becomes expensive as the number of profiles grows.

### 7.3 DTW with DBA centroids

This recipe performs partitional clustering under constrained DTW and estimates one prototype per cluster with Dynamic Time Warping Barycenter Averaging.

A DBA prototype is not a pointwise mean. The procedure repeatedly aligns member series to an evolving barycentre before updating it. The method therefore tries to summarize the common pattern in aligned time.

It requires a chosen K and a specified DTW warping window.

### 7.4 Hierarchical clustering over DTW

Agglomerative hierarchical clustering starts with one profile per cluster and repeatedly merges groups. Here, the pairwise dissimilarities come from constrained DTW and group-to-group distance is defined by complete linkage: the largest dissimilarity between members of the two groups.

Once the distance matrix is fixed, the hierarchy is deterministic. The resulting dendrogram can be cut at several values of K without recomputing the pairwise distances. Its main structural limitation is that an early merge cannot later be undone.

### 7.5 k-Shape

k-Shape is a partitional time-series method built around SBD and shape centroids. It was designed for z-normalized time-series morphology and uses cross-correlation to account for phase shifts.

The method requires K and an ordered sequence. Its notion of similarity is deliberately different from pointwise Euclidean comparison.

### 7.6 Self-Organising Map (SOM)

A Self-Organising Map maps high-dimensional observations onto a usually two-dimensional grid. During training, neighbouring map units are updated together, which encourages nearby units to represent similar parts of the input space.

The implementation has three stages:

1. `kohonen` trains the map;
2. each observation is assigned to its best-matching unit;
3. the codebook vectors are grouped with K-means to obtain the requested final hard clusters.

The final partition therefore depends on both SOM training and the later grouping of codebook vectors. The map can reveal nonlinear organization in the data, but that does not make it inherently preferable to a simpler Euclidean baseline.

### 7.7 Gaussian Mixture Model (GMM)

A finite Gaussian mixture assumes that observations come from K Gaussian component densities:

$$
p(\mathbf{x}) = \sum_{k=1}^{K}\pi_k
\mathcal{N}(\mathbf{x}\mid\mu_k,\Sigma_k).
$$

Expectation-maximisation is used to estimate the mixture weights, component means and covariance structure. Each observation receives posterior probabilities for the fitted components, and the final class assignment is derived from those probabilities.

Covariance estimation becomes unstable when the representation is high-dimensional relative to the number of meters. The implemented recipe therefore applies PCA when needed and restricts `mclust` to parsimonious covariance families.

### 7.8 HDBSCAN

HDBSCAN builds a hierarchy of density-connected regions and extracts groups that persist across density levels. Unlike the K-dependent methods in the benchmark, it does not receive a requested number of clusters.

Profiles can be labelled as noise (`cluster 0`) rather than being forced into a group. The exposed `min_points` parameter controls the amount of local evidence required for a dense region. Larger values generally favour broader, more persistent groups and may increase the number of profiles classified as noise.

The recommendation rule applies a configurable ceiling to the accepted noise share.

### 7.9 Soft-DTW partitional clustering

This recipe performs partitional time-series clustering using Soft-DTW dissimilarity and Soft-DTW centroids. It is only available for the ordered 168-hour typical-week representation.

Both `gamma` and computational cost are part of the comparison. A Soft-DTW result is most useful when judged alongside the constrained-DTW and Euclidean baselines rather than in isolation.

### 7.10 Autoencoder followed by K-means

The encoder is trained to compress the input into a nonlinear latent vector by minimizing reconstruction error:

```text
input -> encoder -> latent z -> decoder -> reconstruction
                              |
                               `-> K-means
```

K-means is then fitted to the learned latent representation.

This is intentionally an exploratory recipe. Its result depends on network architecture, optimization, initialization and sample size in addition to the clustering step. The implementation is an autoencoder used for representation learning followed by K-means; it is not joint Deep Embedded Clustering (DEC).

The Torch CPU runtime is required. Any advantage should be demonstrated against simpler alternatives such as PCA or engineered features rather than assumed from the use of a neural network.

## 8. Experiment recipes

| Recipe | Compatible representation | Similarity | Algorithm | Role in benchmark |
|---|---|---|---|---|
| `kmeans_euclidean` | All | Euclidean | K-means | Baseline |
| `pam_euclidean` | All | Euclidean | PAM | Baseline |
| `pam_manhattan` | All | Manhattan | PAM | Literature-backed comparison |
| `pam_dtw` | Typical week | Constrained DTW | PAM | Literature-backed comparison |
| `dtw_dba` | Typical week | Constrained DTW | Partitional DBA | Extension |
| `dtw_hclust` | Typical week | Constrained DTW | Complete-linkage HAC | Literature-backed comparison |
| `kshape` | Typical week | SBD | k-Shape | Literature-backed comparison |
| `som_euclidean` | All | Euclidean map input | SOM + codebook grouping | Literature-backed comparison |
| `gmm_model` | Feature/PCA | Euclidean geometry in the fitted feature embedding | GMM | Literature-backed comparison |
| `hdbscan_euclidean` | Feature/PCA | Euclidean | HDBSCAN | Extension |
| `hdbscan_manhattan` | Feature/PCA | Manhattan | HDBSCAN | Extension |
| `soft_dtw` | Typical week | Soft-DTW | Partitional Soft-DTW | Extension |
| `deep_autoencoder` | Feature/PCA | Latent Euclidean | Autoencoder + K-means | Exploratory |

Combinations that are not meaningful for a representation are not forced through the pipeline. They are omitted or recorded as skipped.

## 9. Choosing K and evaluating a partition

There is no internal clustering metric that can establish a unique true segmentation. The benchmark therefore reports several pieces of evidence rather than treating one score as ground truth.

### 9.1 Silhouette

For observation `i`:

- `a(i)` is its mean dissimilarity to other observations in the same cluster;
- `b(i)` is the smallest mean dissimilarity from `i` to another cluster;
- `s(i) = (b(i)-a(i))/max(a(i),b(i))`.

A value close to `1` indicates that the observation is much closer to its own cluster than to neighbouring clusters. Values around `0` are typical of overlapping boundaries. A negative value means that, under the chosen dissimilarity, another cluster is on average closer.

The benchmark reports mean silhouette using the validation dissimilarity declared by each recipe. HDBSCAN noise points are excluded.

### 9.2 Conditional subsample stability

Stability is estimated by repeatedly fitting a candidate on random 80% subsets of the meters. Partitions are compared on meters shared by pairs of subsamples using the Adjusted Rand Index.

An ARI of `1` means that the two partitions agree up to a permutation of the cluster labels. Values around `0` indicate agreement close to chance, while negative values indicate less agreement than expected by chance.

This is **conditional subsample stability**: it measures sensitivity to which meters happen to be included while keeping the already constructed representation fixed. It is not temporal stability and it is not an end-to-end perturbation of every preprocessing step. A separate time-based validation would be needed to study whether the typology persists across periods.

### 9.3 Dunn index

$$
D = \frac{\min\text{ between-cluster separation}}
         {\max\text{ within-cluster diameter}}.
$$

Higher values correspond to clusters that are compact relative to their separation. Because both the numerator and denominator depend on extremes, the index can be sensitive to atypical observations.

Dunn is reported as an additional diagnostic. It does not receive a direct weight in the automatic recommendation.

### 9.4 Cluster balance and minimum cluster share

Balance is calculated as the size of the smallest non-noise cluster divided by the size of the largest. A value of `1` means equal cluster sizes.

Equal groups are not inherently better, but a very small cluster can be a sign of fragmentation or a model that is isolating a few unusual profiles. The default recommendation gate requires every non-noise cluster to contain at least 5% of accepted meters. The threshold can be changed by the user.

Candidates that fail the threshold are still shown. They are simply excluded from automatic recommendation.

### 9.5 HDBSCAN noise share

For HDBSCAN, noise share is the fraction of accepted profiles assigned to cluster zero.

Noise can be a legitimate result rather than a fitting error. At the same time, a partition that leaves most profiles unassigned may be of little practical use. The default recommendation ceiling is 20%.

### 9.6 Runtime

Runtime is reported as a cost measure, not as evidence of clustering quality. Pairwise DTW-based methods are usually much more expensive than Euclidean alternatives.

A small improvement in validation metrics may not justify a large increase in computation, especially if the intended use involves repeated fitting or larger datasets.

## 10. Recommendation rule

A candidate can only enter the automatic ranking if it:

1. fitted successfully;
2. satisfies the minimum cluster-share threshold;
3. satisfies the minimum silhouette threshold;
4. satisfies the minimum stability threshold;
5. remains below the maximum allowed noise share when the method can produce noise.

Among eligible candidates, silhouette, stability and balance are each rescaled to `[0,1]` within the current run. The configured weights are normalized to sum to one. A small penalty of `0.01 × K` is then applied so that, when the evidence is otherwise similar, a simpler partition is preferred.

The default weights are:

- silhouette: 0.55;
- stability: 0.30;
- balance: 0.15.

The resulting score is only a ranking rule for the candidates fitted in that run. It is not an accuracy measure and it does not establish a true K. The recommended model still needs to be checked against the actual load curves and the intended interpretation.

## 11. Reading the outputs

### Cluster profile and member curves

The displayed cluster profile is the mean normalized 168-hour curve of the members assigned to that cluster. It is useful as a summary, but it should always be read together with the individual curves or percentile bands. A smooth average can hide two quite different sub-patterns.

### PCA projection

The PCA view projects each meter into two dimensions for inspection. Distance on this chart is only a two-dimensional approximation of the active numerical representation.

Overlap in the plot does not prove that clusters overlap in the full space, and visually separated groups can also be a projection artefact.

### Dendrogram

The dendrogram is only available when hierarchical DTW is the active method. Merge height shows the dissimilarity at which branches are joined. The same fitted tree can be cut at another K without recomputing the DTW distance matrix.

The application does not manufacture a hierarchy for flat methods such as K-means or PAM.

### Diagnostics shared across methods

Every successful fit is passed through the same post-fitting diagnostics where those quantities are defined:

- profile-level silhouette for non-noise observations, using the validation dissimilarity declared by the recipe;
- mean dissimilarity from each profile to the other members of its assigned cluster;
- a profile-by-profile dissimilarity matrix ordered by the active cluster assignment;
- cluster sizes, smallest-cluster share, balance and noise share;
- a two-dimensional PCA projection of the active numerical representation;
- synthetic hourly cluster profiles, member curves, percentile bands and annual calendar heatmaps;
- assignment and atypicality records for every accepted profile.

These diagnostics do not replace the geometry of the fitted method. They answer different questions.

A GMM, for example, may be fitted on reduced features and evaluated in the same feature embedding used to fit the mixture. Posterior probabilities remain a separate measure of assignment confidence, while the weekly consumption curves are shown afterwards to understand what the assigned meters actually do through the week.

### Diagnostics specific to each method

The **Algorithm-specific** area only shows quantities that belong to the active fitted model:

- **K-means:** within-cluster sums of squares, between-cluster share and arithmetic centroids;
- **PAM:** observed medoids and exact distance to the assigned medoid;
- **DTW + DBA:** DBA barycentres and an exact constrained warping path;
- **hierarchical DTW:** the complete-linkage dendrogram;
- **k-Shape:** shape centroids, SBD-aligned curves and distance to the centroid;
- **SOM:** hit/cluster map, U-Matrix neighbour distances and prototypes;
- **GMM:** posterior probability matrix, classification confidence and covariance-model BIC;
- **HDBSCAN:** membership strength, outlier scores and the fitted mutual-reachability hierarchy when the installed implementation exposes it;
- **Soft-DTW:** fitted Soft-DTW centroids;
- **autoencoder + K-means:** latent geometry, epoch loss and profile-level reconstruction error.

### Calendar heatmap

For the calendar heatmap, consumption is first divided by each meter's own mean and then averaged by active cluster, day of year and hour.

The heatmap is an interpretation view, not a clustering input. Grey cells indicate that no observation was available for that calendar position; they do not represent zero consumption.

### Atypicality

Atypicality is based on the mean dissimilarity from a profile to the other members of its assigned cluster.

Large values identify observations near the edge of a group or clusters with substantial internal heterogeneity. They are not, by themselves, evidence that a meter is erroneous.

### Cluster sizes

Cluster size should be checked before giving a partition a substantive interpretation. A very small group may be fragmentation, but it can also represent a real specialist pattern. The distinction has to come from the curves and the application context, not from size alone.

## 12. Design choices and relation to the literature

Several choices in the benchmark come directly from recurring issues in the load-profile clustering literature.

Representation is treated as a first-class modelling decision because annual averaging, weekly summaries, engineered features and sequence representations answer different questions. Daily archetypes and meter-level typologies are kept conceptually separate for the same reason.

Shape and magnitude are also separated deliberately. A normalized weekly curve can reveal routine independent of consumption level, while an unnormalized or feature-based representation can retain demand magnitude when that is relevant. Neither interpretation should appear accidentally because of an unnoticed preprocessing step.

Seasonality and weekday/weekend structure are retained in several representations because both can materially change household or meter behaviour. Sequence methods are given explicit timing constraints: DTW is only useful when the allowed warping still has a physical interpretation.

Simple baselines remain part of the benchmark. A more complicated method has to improve on Euclidean K-means or PAM in some meaningful way before its extra cost or assumptions are worth carrying. The same principle applies to the autoencoder experiment, which is included as a hypothesis to test rather than as an assumed improvement over PCA.

Model selection is deliberately multi-criteria. Silhouette is useful, but a partition with a good average silhouette can still be unstable, badly imbalanced or difficult to interpret. Stability, cluster-size distribution, runtime and the actual load curves are therefore kept alongside the usual internal indices.

Metadata are not used to force the consumption clusters to reproduce known customer categories. They are better suited to checking, explaining or validating patterns found from the consumption data itself.

For very large daily datasets, a full all-pairs DTW calculation would quickly become impractical. A more scalable daily-archetype study would learn prototypes on a suitable sample and then assign the remaining days to those prototypes rather than constructing one enormous distance matrix.

The main contribution of this repository is therefore not a new clustering estimator. It is the way the comparison is organized and implemented:

- representation, normalization, dimensionality reduction, distance and clustering are recorded separately;
- very different clustering families are compared through a common validation layer without discarding method-specific diagnostics;
- numerical validation remains connected to hourly curves, profile bands, annual heatmaps, cluster sizes and atypical meters;
- timestamp checks, natural-year eligibility, hourly alignment, bounded imputation and exclusion rules are shared by the RStudio workflow, CLI and Shiny app;
- all three interfaces call the same analytical functions;
- fitting the benchmark is kept separate from browsing one selected result, so changing the active model in the app does not alter the fitted evidence.

These choices make experiments easier to reproduce and easier to inspect. They do not turn the small, diversity-oriented GoiEner sample into evidence for a general population typology. Generalization across regions, semantic labels, operational usefulness and downstream decisions would need separate empirical validation.

## 13. Methods not implemented

The following approaches are relevant to the problem but are not part of the executable benchmark:

- PAA, SAX, Fourier and wavelet representations;
- autocorrelation and quantile-autocovariance representations;
- HMM/Markov and state-space representations;
- KL and other distributional divergences;
- fuzzy C-means and spectral or graph clustering;
- the two-level daily-archetype pipeline described earlier;
- temporal holdout stability;
- Davies-Bouldin and Calinski-Harabasz indices.

They are possible extensions, not features of the current implementation.

## 14. References

- Aghabozorgi, S., Shirkhorshidi, A. S. and Wah, T. Y. (2015). *Time-series
  clustering — A decade review*. Information Systems, 53, 16–38.
  [https://doi.org/10.1016/j.is.2015.04.007](https://doi.org/10.1016/j.is.2015.04.007)
- Cuturi, M. and Blondel, M. (2017). *Soft-DTW: a differentiable loss function
  for time-series*. Proceedings of ICML 2017, 894–903.
  [https://proceedings.mlr.press/v70/cuturi17a.html](https://proceedings.mlr.press/v70/cuturi17a.html)
- McLoughlin, F., Duffy, A. and Conlon, M. (2015). *A clustering approach to
  domestic electricity load profile characterisation using smart metering
  data*. Applied Energy, 141, 190–199.
  [https://doi.org/10.1016/j.apenergy.2014.12.039](https://doi.org/10.1016/j.apenergy.2014.12.039)
- Paparrizos, J. and Gravano, L. (2015). *k-Shape: efficient and accurate
  clustering of time series*. Proceedings of SIGMOD 2015, 1855–1870.
  [https://doi.org/10.1145/2723372.2737793](https://doi.org/10.1145/2723372.2737793)
- Petitjean, F., Ketterlin, A. and Gançarski, P. (2011). *A global averaging
  method for dynamic time warping, with applications to clustering*. Pattern
  Recognition, 44(3), 678–693.
  [https://doi.org/10.1016/j.patcog.2010.09.013](https://doi.org/10.1016/j.patcog.2010.09.013)
- Quesada, C., Montero-Manso, P., Pflugradt, N., Astigarraga, L., Merveille, C.,
  Casado-Mansilla, D. and Borges, C. E. (2025). *A data-driven methodology for
  deriving electricity consumption typologies from smart meters*. Energy
  Reports, 14, 2420–2434.
  [https://doi.org/10.1016/j.egyr.2025.09.002](https://doi.org/10.1016/j.egyr.2025.09.002)
- Rajabi, A. et al. (2020). *A comparative study of clustering techniques for
  electrical load pattern segmentation*. Renewable and Sustainable Energy
  Reviews, 120, 109628.
  [https://doi.org/10.1016/j.rser.2019.109628](https://doi.org/10.1016/j.rser.2019.109628)
- Tureczek, A. and Nielsen, P. S. (2017). *Structured literature review of
  electricity consumption classification using smart meter data*. Energies,
  10(5), 584.
  [https://doi.org/10.3390/en10050584](https://doi.org/10.3390/en10050584)
- Yilmaz, S., Chambers, J. and Patel, M. K. (2019). *Comparison of clustering
  approaches for domestic electricity load profile characterisation:
  implications for demand side management*. Energy, 180, 665–677.
  [https://doi.org/10.1016/j.energy.2019.05.124](https://doi.org/10.1016/j.energy.2019.05.124)

## 15. Before interpreting a result

A useful final check is to describe the fitted model in plain language:

> We grouped **meters**, represented by **X**, normalized to preserve **Y**,
> considered two meters similar when **Z**, and formed the groups using **A**.
> The result was checked with **B** and interpreted using **C** load-profile
> diagnostics.

If that description is still vague, the model specification or its interpretation probably needs another pass.
