import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

cachedNetworkImage(mediaUrl) {
  return CachedNetworkImage(
    imageUrl: mediaUrl,
    fit: BoxFit.cover,
    placeholder: (_, __) => Padding(
      padding: EdgeInsets.all(20),
      child: CircularProgressIndicator(),
    ),
    errorWidget: (_, __, ___) => Icon(Icons.error),
  );
}
