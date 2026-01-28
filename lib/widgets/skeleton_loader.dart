import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_dimensions.dart';

/// Animated skeleton loader widget with shimmer effect
class SkeletonLoader extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;
  final EdgeInsets? margin;
  final Curve? curve;

  const SkeletonLoader({
    Key? key,
    required this.width,
    required this.height,
    this.borderRadius,
    this.margin,
    this.curve,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: widget.margin,
      child: ShimmerEffect(
        animation: _animationController,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius:
                widget.borderRadius ?? BorderRadius.circular(AppRadius.md),
          ),
        ),
      ),
    );
  }
}

/// Shimmer animation effect wrapper
class ShimmerEffect extends StatelessWidget {
  final Animation<double> animation;
  final Widget child;

  const ShimmerEffect({
    Key? key,
    required this.animation,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment(-1.0 - animation.value * 2, 0),
              end: Alignment(1.0 - animation.value * 2, 0),
              colors: [
                Colors.grey[400]!,
                Colors.grey[200]!,
                Colors.grey[400]!,
              ],
              stops: const [0.0, 0.5, 1.0],
            ).createShader(bounds);
          },
          child: child,
        );
      },
    );
  }
}

/// Skeleton loader untuk transaction card
class TransactionCardSkeleton extends StatelessWidget {
  final EdgeInsets? margin;

  const TransactionCardSkeleton({
    Key? key,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: [
          // Header row
          Row(
            children: [
              SkeletonLoader(
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonLoader(
                      width: double.infinity,
                      height: 16,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      margin: EdgeInsets.only(bottom: AppSpacing.sm),
                    ),
                    SkeletonLoader(
                      width: 150,
                      height: 14,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                  ],
                ),
              ),
              SkeletonLoader(
                width: 80,
                height: 20,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader untuk dashboard stats card
class StatsCardSkeleton extends StatelessWidget {
  final EdgeInsets? margin;

  const StatsCardSkeleton({
    Key? key,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon placeholder
          SkeletonLoader(
            width: 40,
            height: 40,
            borderRadius: BorderRadius.circular(AppRadius.md),
            margin: EdgeInsets.only(bottom: AppSpacing.md),
          ),
          // Title placeholder
          SkeletonLoader(
            width: 120,
            height: 14,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          // Value placeholder
          SkeletonLoader(
            width: 150,
            height: 28,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          // Change percentage placeholder
          SkeletonLoader(
            width: 100,
            height: 12,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader untuk table rows
class TableRowSkeleton extends StatelessWidget {
  final int columnCount;
  final EdgeInsets? margin;

  const TableRowSkeleton({
    Key? key,
    this.columnCount = 4,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey[200]!,
            width: AppSizes.dividerThickness,
          ),
        ),
      ),
      child: Row(
        children: List.generate(
          columnCount,
          (index) => Expanded(
            child: SkeletonLoader(
              width: double.infinity,
              height: 16,
              borderRadius: BorderRadius.circular(AppRadius.sm),
              margin: EdgeInsets.only(
                right: index < columnCount - 1 ? AppSpacing.md : 0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Skeleton loader untuk form input
class InputFieldSkeleton extends StatelessWidget {
  final EdgeInsets? margin;

  const InputFieldSkeleton({
    Key? key,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          SkeletonLoader(
            width: 100,
            height: 14,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            margin: EdgeInsets.only(bottom: AppSpacing.sm),
          ),
          // Input field
          SkeletonLoader(
            width: double.infinity,
            height: AppSizes.inputHeight,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader untuk list
class ListViewSkeleton extends StatelessWidget {
  final int itemCount;
  final bool isTransactionType;
  final EdgeInsets? padding;

  const ListViewSkeleton({
    Key? key,
    this.itemCount = 5,
    this.isTransactionType = true,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: padding ?? EdgeInsets.all(AppSpacing.lg),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (isTransactionType) {
          return TransactionCardSkeleton(
            margin: EdgeInsets.only(bottom: AppSpacing.md),
          );
        } else {
          return TableRowSkeleton(
            margin: EdgeInsets.only(bottom: AppSpacing.md),
          );
        }
      },
    );
  }
}

/// Full page skeleton loader
class PageSkeleton extends StatelessWidget {
  final EdgeInsets? padding;

  const PageSkeleton({
    Key? key,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: padding ?? EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header skeleton
          SkeletonLoader(
            width: 200,
            height: 32,
            borderRadius: BorderRadius.circular(AppRadius.md),
            margin: EdgeInsets.only(bottom: AppSpacing.xl),
          ),
          // Stats cards skeleton
          Row(
            children: List.generate(
              3,
              (index) => Expanded(
                child: StatsCardSkeleton(
                  margin: EdgeInsets.only(right: AppSpacing.md),
                ),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.xl),
          // List skeleton
          ListViewSkeleton(
            itemCount: 5,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }
}
