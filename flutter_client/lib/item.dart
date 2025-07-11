import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class Item {
  final String code;
  final String name;
  final String description;
  final String effect;

  Item({
    required this.code,
    required this.name,
    required this.description,
    required this.effect,
  });

  // JSON 데이터를 Item 객체로 변환하는 팩토리 생성자
  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      code: json['code'],
      name: json['name'],
      description: json['description'],
      effect: json['effect'],
    );
  }
}

// 게임 월드에 표시될 아이템 컴포넌트
class ItemComponent extends TextComponent with CollisionCallbacks {
  final Item itemData;

  ItemComponent({required this.itemData, required Vector2 position})
      : super(
          text: itemData.name, // 아이템 이름을 텍스트로 표시
          position: position,
          anchor: Anchor.center, // 텍스트 중앙 정렬
          textRenderer: TextPaint(
            style: const TextStyle(
              color: Colors.yellow, // 텍스트 색상
              fontSize: 12, // 텍스트 크기
              fontWeight: FontWeight.bold,
            ),
          ),
        );

  @override
  Future<void> onLoad() async {
    super.onLoad();
    // 충돌 감지를 위한 Hitbox 추가 (텍스트 크기에 맞게 조정)
    add(RectangleHitbox(size: Vector2(16, 16))); // 텍스트 크기에 맞춰 hitbox 크기 조정
  }
}