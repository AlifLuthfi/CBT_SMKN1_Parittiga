import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
class AppTextStyles {
  AppTextStyles._();
  static TextStyle get h1       => GoogleFonts.inter(fontSize:28,fontWeight:FontWeight.w700,color:AppColors.ink);
  static TextStyle get h2       => GoogleFonts.inter(fontSize:22,fontWeight:FontWeight.w700,color:AppColors.ink);
  static TextStyle get h3       => GoogleFonts.inter(fontSize:18,fontWeight:FontWeight.w600,color:AppColors.ink);
  static TextStyle get h4       => GoogleFonts.inter(fontSize:16,fontWeight:FontWeight.w600,color:AppColors.ink);
  static TextStyle get body     => GoogleFonts.inter(fontSize:14,fontWeight:FontWeight.w400,color:AppColors.ink2);
  static TextStyle get bodySmall=> GoogleFonts.inter(fontSize:12,fontWeight:FontWeight.w400,color:AppColors.ink3);
  static TextStyle get label    => GoogleFonts.inter(fontSize:11,fontWeight:FontWeight.w600,color:AppColors.ink3,letterSpacing:.5);
  static TextStyle get button   => GoogleFonts.inter(fontSize:14,fontWeight:FontWeight.w600,color:Colors.white);
  static TextStyle get mono     => const TextStyle(fontFamily:'JetBrainsMono',fontSize:14,color:AppColors.ink);
  static TextStyle get monoLg   => const TextStyle(fontFamily:'JetBrainsMono',fontSize:28,fontWeight:FontWeight.w700,color:AppColors.ink);
}
