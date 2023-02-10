import 'package:engelsburg_planer/src/view/widgets/util/label.dart';
import 'package:flutter/material.dart';

class TaskCard extends StatefulWidget {
  const TaskCard({Key? key}) : super(key: key);

  @override
  State<TaskCard> createState() => _TaskCardState();
}

class _TaskCardState extends State<TaskCard> {
  bool done = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 600,
      decoration: BoxDecoration(
        color: Theme.of(context).dividerColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          "Aufgabe 1",
                          textScaleFactor: 2.2,
                          style: TextStyle(
                            fontWeight: done ? FontWeight.w300 : FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Wrap(
                          children: [
                            const Label(
                              "Mathematik",
                              backgroundColor: Colors.blueAccent,
                            ),
                            Label(
                              "von 18.04.",
                              backgroundColor: Theme.of(context).disabledColor,
                            ),
                            const Label(
                              "bis Montag (20.04.)",
                              backgroundColor: Colors.orange,
                            ),
                          ],
                        ),
                      ),
                      if (true) //TODO change to description != null
                        Wrap(
                          children: [
                            Text(
                              "Beschreibung hier sed diam voluptua. At vero eos et accusam et justo duo dolores et ea.",
                              style: TextStyle(
                                fontWeight: done ? FontWeight.normal : FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(done ? Icons.clear : Icons.check),
                onPressed: () {
                  setState(() {
                    done = !done;
                  });
                },
              )
            ],
          ),
        ),
      ),
    );
  }
}
