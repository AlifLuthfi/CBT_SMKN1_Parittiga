import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class SkeletonBox extends StatelessWidget {
  final double? width; final double height; final double radius;
  const SkeletonBox({super.key, this.width, this.height=14, this.radius=6});
  @override
  Widget build(BuildContext context) => Shimmer.fromColors(
    baseColor: const Color(0xFFE8EBEF), highlightColor: const Color(0xFFF4F6F8),
    child: Container(width:width, height:height, decoration:BoxDecoration(color:Colors.white, borderRadius:BorderRadius.circular(radius))),
  );
}

class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color:AppColors.surface, borderRadius:BorderRadius.circular(12), border:Border.all(color:AppColors.border)),
    child: const Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      SkeletonBox(width:120, height:11), SizedBox(height:10),
      SkeletonBox(width:70,  height:32, radius:6), SizedBox(height:8),
      SkeletonBox(width:140, height:11),
    ]),
  );
}

class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key});
  @override
  Widget build(BuildContext context) => const Padding(
    padding: EdgeInsets.symmetric(horizontal:16, vertical:11),
    child: Row(children:[
      SkeletonBox(width:40, height:40, radius:8), SizedBox(width:12),
      Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
        SkeletonBox(height:13), SizedBox(height:6), SkeletonBox(width:160, height:11),
      ])),
      SizedBox(width:12), SkeletonBox(width:60, height:24, radius:12),
    ]),
  );
}

class StatusBadge extends StatelessWidget {
  final String label; final Color color; final Color bgColor;
  const StatusBadge({super.key, required this.label, required this.color, required this.bgColor});

  factory StatusBadge.fromStatus(String status) {
    const m = {
      'active':     ('Aktif',       AppColors.green,  AppColors.greenLight),
      'scheduled':  ('Terjadwal',   Color(0xFF92400E), AppColors.amberLight),
      'ended':      ('Selesai',     AppColors.sky,     AppColors.skyLight),
      'draft':      ('Draft',       AppColors.ink3,    AppColors.bg),
      'paused':     ('Dijeda',      AppColors.orange,  AppColors.orangeLight),
      'submitted':  ('Dikumpulkan', AppColors.green,   AppColors.greenLight),
      'timeout':    ('Timeout',     AppColors.red,     AppColors.redLight),
      'in_progress':('Berlangsung', AppColors.navy,    AppColors.navyLight),
    };
    final e = m[status];
    if (e == null) return StatusBadge(label:status, color:AppColors.ink3, bgColor:AppColors.bg);
    return StatusBadge(label:e.$1, color:e.$2, bgColor:e.$3);
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal:10, vertical:4),
    decoration: BoxDecoration(color:bgColor, borderRadius:BorderRadius.circular(20)),
    child: Text(label, style:AppTextStyles.bodySmall.copyWith(color:color, fontWeight:FontWeight.w600, fontSize:11)),
  );
}

class StatCard extends StatelessWidget {
  final String label, value, subtitle; final Color accentColor; final bool loading;
  const StatCard({super.key, required this.label, required this.value, this.subtitle='', required this.accentColor, this.loading=false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppColors.border),
    ),
    // ponytail: left accent border disederhanakan — pakai GradientBorder kalau Flutter sudah support
    foregroundDecoration: BoxDecoration(
      borderRadius: BorderRadius.circular(10),
      border: Border(left: BorderSide(color: accentColor, width: 5)),
    ),
    child: loading ? const SkeletonCard() : Column(crossAxisAlignment:CrossAxisAlignment.start, children:[
      Row(mainAxisAlignment:MainAxisAlignment.spaceBetween, children:[
        Text(label.toUpperCase(), style:AppTextStyles.label),
        Container(width:7, height:7, decoration:BoxDecoration(color:accentColor, shape:BoxShape.circle)),
      ]),
      const SizedBox(height:10),
      Text(value, style:AppTextStyles.monoLg.copyWith(fontSize:30)),
      if (subtitle.isNotEmpty)...[const SizedBox(height:4), Text(subtitle, style:AppTextStyles.bodySmall)],
    ]),
  );
}

class EmptyState extends StatelessWidget {
  final String title, subtitle; final IconData icon; final Widget? action;
  const EmptyState({super.key, required this.title, this.subtitle='', this.icon=Icons.inbox_outlined, this.action});
  @override
  Widget build(BuildContext context) => Center(child:Padding(padding:const EdgeInsets.all(32), child:Column(mainAxisSize:MainAxisSize.min, children:[
    Icon(icon, size:64, color:AppColors.ink3.withOpacity(.4)),
    const SizedBox(height:16),
    Text(title, style:AppTextStyles.h4.copyWith(color:AppColors.ink3), textAlign:TextAlign.center),
    if (subtitle.isNotEmpty)...[const SizedBox(height:6), Text(subtitle, style:AppTextStyles.bodySmall, textAlign:TextAlign.center)],
    if (action!=null)...[const SizedBox(height:20), action!],
  ])));
}

class ErrorState extends StatelessWidget {
  final String message; final VoidCallback? onRetry;
  const ErrorState({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) => Center(child:Padding(padding:const EdgeInsets.all(32), child:Column(mainAxisSize:MainAxisSize.min, children:[
    Icon(Icons.error_outline, size:56, color:AppColors.red.withOpacity(.5)),
    const SizedBox(height:14),
    Text('Terjadi Kesalahan', style:AppTextStyles.h4),
    const SizedBox(height:6),
    Text(message, style:AppTextStyles.bodySmall, textAlign:TextAlign.center),
    if (onRetry!=null)...[const SizedBox(height:20), SizedBox(width:160, child:OutlinedButton.icon(onPressed:onRetry, icon:const Icon(Icons.refresh,size:16), label:const Text('Coba Lagi')))],
  ])));
}

class AppButton extends StatelessWidget {
  final String label; final VoidCallback? onPressed; final bool loading, outlined; final IconData? icon; final Color? color;
  const AppButton({super.key, required this.label, this.onPressed, this.loading=false, this.outlined=false, this.icon, this.color});
  @override
  Widget build(BuildContext context) {
    final c = loading
        ? const SizedBox(width:20, height:20, child:CircularProgressIndicator(strokeWidth:2.5, color:Colors.white))
        : icon!=null
            ? Row(mainAxisSize:MainAxisSize.min, mainAxisAlignment:MainAxisAlignment.center, children:[Icon(icon,size:18,color:outlined?(color??AppColors.navy):Colors.white), const SizedBox(width:7), Text(label,style:AppTextStyles.button.copyWith(color:outlined?(color??AppColors.navy):Colors.white))])
            : Text(label, style:AppTextStyles.button.copyWith(color:outlined?(color??AppColors.navy):Colors.white));
    return outlined
        ? OutlinedButton(onPressed:loading?null:onPressed, style:OutlinedButton.styleFrom(foregroundColor:color??AppColors.navy, side:BorderSide(color:color??AppColors.navy)), child:c)
        : ElevatedButton(onPressed:loading?null:onPressed, style:ElevatedButton.styleFrom(backgroundColor:color??AppColors.navy), child:c);
  }
}

class InfoRow extends StatelessWidget {
  final IconData icon; final String label, value;
  const InfoRow({super.key, required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical:6),
    child: Row(children:[
      Icon(icon, size:15, color:AppColors.ink3), const SizedBox(width:8),
      Text('$label: ', style:AppTextStyles.bodySmall),
      Expanded(child:Text(value, style:AppTextStyles.bodySmall.copyWith(color:AppColors.ink, fontWeight:FontWeight.w500))),
    ]),
  );
}
