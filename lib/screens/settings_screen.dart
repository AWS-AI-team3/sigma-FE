import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dotted_line/dotted_line.dart';

void main() {
  runApp(const MaterialApp(home: SettingsScreen()));
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final List<String> gestureOptions = [
    '엄지와 검지를',
    '오른손을 모두 펴고',
    '왼손 전체 펴기',
    '엄지 접기',
    '새끼 손가락 접기',
    '선택 안함',
  ];

  String _leftClickValue = '선택 안함';
  String _rightClickValue = '선택 안함';
  String _wheelScrollValue = '선택 안함';
  String _recordStartValue = '선택 안함';
  String _recordStopValue = '선택 안함';

  bool _showMouseCursor = true;
  bool _showSkeleton = false;
  bool _useLeftHand = true;

  static const double labelWidth = 70;

  //  현재 클릭된 드롭다운 라벨 저장
  String? _activeDropdownLabel;

  Color getDropdownColor(String value, {bool isActive = false}) {
    if (isActive) return const Color.fromARGB(255, 196, 148, 223); // 활성 시 주황색
    return value == '선택 안함'
        ? const Color(0xFFA0A0A0)
        : const Color(0xFF7DAEF3);
  }

  void _saveSettings() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('설정이 저장되었습니다'),
        backgroundColor: Color(0xFF6186FF),
      ),
    );
  }

  Future<void> _showCustomDropdownMenu(
      BuildContext context,
      GlobalKey iconKey,
      String currentValue,
      ValueChanged<String> onSelected,
      String label) async {
    // 아이콘 클릭 시 현재 드롭다운 활성 상태로 표시
    setState(() {
      _activeDropdownLabel = label;
    });

    RenderBox button =
        iconKey.currentContext!.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset pos =
        button.localToGlobal(Offset(0, button.size.height), ancestor: overlay);

    final RelativeRect position = RelativeRect.fromLTRB(
      pos.dx,
      pos.dy,
      pos.dx + button.size.width,
      overlay.size.height - pos.dy,
    );

    final selected = await showMenu<String>(
      context: context,
      position: position,
      items: gestureOptions.map((option) {
        return PopupMenuItem<String>(
          value: option,
          child: Text(
            option,
            style: GoogleFonts.roboto(
              fontSize: 13,
              color: option == '선택 안함'
                  ? const Color(0xFFA0A0A0)
                  : Colors.black,
            ),
          ),
        );
      }).toList(),
    );

    if (selected != null && selected != currentValue) {
      onSelected(selected);
    }

    // 메뉴 닫히면 비활성화
    setState(() {
      _activeDropdownLabel = null;
    });
  }

  Widget _buildGestureDropdown(
      BuildContext context, String label, String value, ValueChanged<String> onChanged) {
    final iconKey = GlobalKey();
    final bool isActive = _activeDropdownLabel == label;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: labelWidth,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF070F27),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 30,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: getDropdownColor(value, isActive: isActive),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.roboto(
                        fontSize: 11,
                        color: value == '선택 안함'
                            ? const Color(0xFFA0A0A0)
                            : Colors.black,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  GestureDetector(
                    key: iconKey,
                    behavior: HitTestBehavior.translucent,
                    onTap: () async {
                      await _showCustomDropdownMenu(
                          context, iconKey, value, onChanged, label);
                    },
                    child: const Icon(Icons.arrow_drop_down,
                        size: 20, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 커스텀 Back 버튼
  Widget _buildBackButton() {
    return _CustomBackButton(
      onTap: () => Navigator.pop(context),
    );
  }

  Widget _buildCapsuleHeaderImage(String assetPath,
      {double width = 154, double height = 34}) {
    return SizedBox(
      width: width,
      height: height,
      child: Image.asset(assetPath, width: width, height: height, fit: BoxFit.fill),
    );
  }

  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF070F27),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.white,
            activeTrackColor: const Color(0xFF313C73),
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFF7F7F7F),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final containerWidth =
        (MediaQuery.of(context).size.width * 0.96).clamp(380.0, 820.0);
    final containerHeight =
        (MediaQuery.of(context).size.height * 0.88).clamp(480.0, 720.0);

    return Scaffold(
      backgroundColor: const Color(0xFFE5E5E5),
      body: Center(
        child: Container(
          width: containerWidth,
          height: containerHeight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.13),
                blurRadius: 8,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(containerWidth * 0.02, 27, containerWidth * 0.02, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings, size: 32, color: Colors.black),
                        const SizedBox(width: 10),
                        Text(
                          'Setting',
                          style: GoogleFonts.roboto(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        )
                      ],
                    ),
                    SizedBox(
                      width: 95,
                      height: 36,
                      child: _buildBackButton(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                height: 3,
                width: double.infinity,
                color: const Color(0xFFCEC8F9),
              ),
              const SizedBox(height: 13),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      flex: 11,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 5, left: 15),
                              child: _buildCapsuleHeaderImage('assets/images/hand_no.png'),
                            ),
                            const SizedBox(height: 20),
                            _buildGestureDropdown(context, '좌클릭', _leftClickValue,
                                (v) => setState(() => _leftClickValue = v)),
                            const SizedBox(height: 15),
                            _buildGestureDropdown(context, '우클릭', _rightClickValue,
                                (v) => setState(() => _rightClickValue = v)),
                            const SizedBox(height: 15),
                            _buildGestureDropdown(context, '휠스크롤', _wheelScrollValue,
                                (v) => setState(() => _wheelScrollValue = v)),
                            const SizedBox(height: 15),
                            _buildGestureDropdown(context, '녹음 시작', _recordStartValue,
                                (v) => setState(() => _recordStartValue = v)),
                            const SizedBox(height: 15),
                            _buildGestureDropdown(context, '녹음 중지', _recordStopValue,
                                (v) => setState(() => _recordStopValue = v)),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: DottedLine(
                        direction: Axis.vertical,
                        lineThickness: 3,
                        dashLength: 6,
                        dashGapLength: 6,
                        dashColor: const Color(0xFFCEC8F9),
                      ),
                    ),
                    Expanded(
                      flex: 11,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: _buildCapsuleHeaderImage('assets/images/screen_no.png'),
                            ),
                            const SizedBox(height: 22),
                            _buildToggleRow('마우스 커서 표시', _showMouseCursor,
                                (v) => setState(() => _showMouseCursor = v)),
                            _buildToggleRow('왼손 사용', _useLeftHand,
                                (v) => setState(() => _useLeftHand = v)),
                            _buildToggleRow('스켈레톤 표시', _showSkeleton,
                                (v) => setState(() => _showSkeleton = v)),
                            const Spacer(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12, top: 3),
                child: SizedBox(
                  width: 120,
                  height: 42,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF88AEFF),
                      foregroundColor: const Color(0xFF070F27),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '저장하기',
                        style: GoogleFonts.roboto(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF070F27),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 마우스 오버 Back 버튼
class _CustomBackButton extends StatefulWidget {
  final VoidCallback onTap;
  const _CustomBackButton({required this.onTap});

  @override
  State<_CustomBackButton> createState() => _CustomBackButtonState();
}

class _CustomBackButtonState extends State<_CustomBackButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() {
          _isHovering = true;
        });
      },
      onExit: (_) {
        setState(() {
          _isHovering = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF6186FF).withOpacity(_isHovering ? 0.85 : 1.0),
          borderRadius: BorderRadius.circular(24),
          boxShadow: _isHovering
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.25),
                    blurRadius: 5,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: widget.onTap,
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                const SizedBox(width: 4),
                Text(
                  'Back',
                  style: GoogleFonts.roboto(
                      color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
