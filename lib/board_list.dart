import 'package:flutter/material.dart';

import './board_item.dart';
import './boardview.dart';

typedef void OnDropList(int? listIndex, int? oldListIndex);
typedef void OnTapList(int? listIndex);
typedef void OnStartDragList(int? listIndex);

class BoardList extends StatefulWidget {
  BoardList({
    Key? key,
    required this.header,
    this.items,
    this.footer,
    this.boardView,
    this.draggable = true,
    this.index,
    this.onDropList,
    this.onTapList,
    this.onStartDragList,
    this.padding,
    this.margin,
    this.decoration,
    this.mainAxisSize = MainAxisSize.min,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  })  : assert(padding == null || padding.isNonNegative),
        assert(margin == null || margin.isNonNegative),
        assert(decoration == null || decoration.debugAssertIsValid()),
        super(key: key);

  final Widget header;
  final List<BoardItem>? items;
  final Widget? footer;
  final BoardViewState? boardView;
  final int? index;
  final OnDropList? onDropList;
  final OnTapList? onTapList;
  final OnStartDragList? onStartDragList;
  final bool draggable;

  // From `Container`.
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Decoration? decoration;

  // Form `Column`.
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  State<StatefulWidget> createState() => BoardListState();
}

class BoardListState extends State<BoardList> with AutomaticKeepAliveClientMixin {
  List<BoardItemState> itemStates = [];
  ScrollController boardListController = new ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (widget.boardView!.listStates.length > widget.index!) {
      widget.boardView!.listStates.removeAt(widget.index!);
    }
    widget.boardView!.listStates.insert(widget.index!, this);

    return Container(
      padding: widget.padding,
      margin: widget.margin,
      decoration: widget.decoration,
      child: Column(
        mainAxisSize: widget.mainAxisSize,
        mainAxisAlignment: widget.mainAxisAlignment,
        crossAxisAlignment: widget.crossAxisAlignment,
        children: [
          _header(),
          Flexible(fit: FlexFit.loose, child: _body()),
          widget.footer ?? Container(),
        ],
      ),
    );
  }

  Widget _header() {
    return GestureDetector(
      onTap: () {
        if (widget.onTapList != null) widget.onTapList!(widget.index);
      },
      onTapDown: (otd) {
        if (widget.draggable) {
          RenderBox object = context.findRenderObject() as RenderBox;
          Offset pos = object.localToGlobal(Offset.zero);
          widget.boardView!.initialX = pos.dx;
          widget.boardView!.initialY = pos.dy;

          widget.boardView!.rightListX = pos.dx + object.size.width;
          widget.boardView!.leftListX = pos.dx;
        }
      },
      onTapCancel: () {},
      // FIXME: Let's user set a custom press duration.
      onLongPress: () {
        if (!widget.boardView!.widget.isSelecting && widget.draggable) {
          _startDrag(widget, context);
        }
      },
      child: widget.header,
    );
  }

  Widget _body() {
    if (widget.items != null) {
      return ListView.builder(
        shrinkWrap: true,
        physics: ClampingScrollPhysics(),
        controller: boardListController,
        itemCount: widget.items!.length,
        itemBuilder: (ctx, index) {
          if (widget.items![index].boardList == null ||
              widget.items![index].index != index ||
              widget.items![index].boardList!.widget.index != widget.index ||
              widget.items![index].boardList != this) {
            widget.items![index] = new BoardItem(
              boardList: this,
              item: widget.items![index].item,
              draggable: widget.items![index].draggable,
              index: index,
              onDropItem: widget.items![index].onDropItem,
              onTapItem: widget.items![index].onTapItem,
              onDragItem: widget.items![index].onDragItem,
              onStartDragItem: widget.items![index].onStartDragItem,
            );
          }
          if (widget.boardView!.draggedItemIndex == index &&
              widget.boardView!.draggedListIndex == widget.index) {
            return Opacity(opacity: 0.0, child: widget.items![index]);
          } else {
            return widget.items![index];
          }
        },
      );
    }

    return Container();
  }

  void _startDrag(Widget item, BuildContext context) {
    if (widget.boardView != null && widget.draggable) {
      if (widget.onStartDragList != null) {
        widget.onStartDragList!(widget.index);
      }
      widget.boardView!.startListIndex = widget.index;
      widget.boardView!.height = context.size!.height;
      widget.boardView!.draggedListIndex = widget.index!;
      widget.boardView!.draggedItemIndex = null;
      widget.boardView!.draggedItem = item;
      widget.boardView!.onDropList = _onDropList;
      widget.boardView!.run();
      if (widget.boardView!.mounted) {
        widget.boardView!.setState(() {});
      }
    }
  }

  void _onDropList(int? listIndex) {
    if (widget.onDropList != null) {
      widget.onDropList!(listIndex, widget.boardView!.startListIndex);
    }
    widget.boardView!.draggedListIndex = null;
    if (widget.boardView!.mounted) {
      widget.boardView!.setState(() {});
    }
  }
}
