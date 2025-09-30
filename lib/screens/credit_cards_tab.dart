import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/data_provider.dart';
import '../models/credit_card.dart';

class CreditCardsTab extends StatelessWidget {
  const CreditCardsTab({super.key});

  void _showDeleteConfirmationDialog(BuildContext context, int index) async {
    final card = Provider.of<DataProvider>(context, listen: false).creditCards[index];
    if (await showDialog(
      context: context,
      builder: (BuildContext context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Colors.deepPurple, Colors.purpleAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Delete Credit Card',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Are you sure you want to delete ${card.name}?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Delete',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    )) {
      Provider.of<DataProvider>(context, listen: false).deleteCreditCard(index);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${card.name} deleted'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
            duration: const Duration(milliseconds: 1500),
          ),
        );
      }
    }
  }

  void _showEditCreditCardDialog(BuildContext context, CreditCard card, int index) {
    final TextEditingController cardNameController = TextEditingController(text: card.name);
    final TextEditingController cardLimitController = TextEditingController(text: card.limit.toString());
    int selectedDay = card.dueDate;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.pinkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Edit Credit Card',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: cardNameController,
                      decoration: const InputDecoration(
                        labelText: 'Card Name',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: cardLimitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Card Limit',
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return Container(
                              height: 400,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade50,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.calendar_today, color: Colors.deepPurple),
                                        SizedBox(width: 8),
                                        Text(
                                          'Select Bill Due Date',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: GridView.builder(
                                      padding: const EdgeInsets.all(16),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 5,
                                        childAspectRatio: 1,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                      itemCount: 31,
                                      itemBuilder: (context, index) {
                                        final day = index + 1;
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedDay = day;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            decoration: BoxDecoration(
                                              color: selectedDay == day
                                                  ? Colors.deepPurple
                                                  : Colors.deepPurple.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                day.toString(),
                                                style: TextStyle(
                                                  color: selectedDay == day
                                                      ? Colors.white
                                                      : Colors.deepPurple,
                                                  fontSize: 16,
                                                  fontWeight: selectedDay == day
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bill Due Date',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.deepPurple),
                                const SizedBox(width: 12),
                                Text(
                                  '${selectedDay}${_getDaySuffix(selectedDay)} of every month',
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.save),
                          label: const Text('Save'),
                          onPressed: () async {
                            if (cardNameController.text.isNotEmpty && cardLimitController.text.isNotEmpty) {
                              final updatedCard = CreditCard(
                                name: cardNameController.text,
                                limit: double.parse(cardLimitController.text),
                                dueDate: selectedDay,
                                addedDate: card.addedDate,
                              );
                              await Provider.of<DataProvider>(context, listen: false)
                                  .updateCreditCard(index, updatedCard);
                              if (context.mounted) {
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Credit card updated successfully!'),
                                    backgroundColor: Colors.deepPurple,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                    duration: Duration(milliseconds: 1500),
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _getDaySuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  void _showAddCreditCardDialog(BuildContext context) {
    final TextEditingController cardNameController = TextEditingController();
    final TextEditingController cardLimitController = TextEditingController();
    int selectedDay = 1;
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple, Colors.pinkAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Add Credit Card',
                      style: TextStyle(
                        fontSize: 24,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: cardNameController,
                      decoration: const InputDecoration(
                        labelText: 'Card Name',
                        filled: true,
                        fillColor: Colors.white
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: cardLimitController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Card Limit',
                        filled: true,
                        fillColor: Colors.white
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (BuildContext context) {
                            return Container(
                              height: 400,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.deepPurple.shade50,
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(20),
                                        topRight: Radius.circular(20),
                                      ),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.calendar_today, color: Colors.deepPurple),
                                        SizedBox(width: 8),
                                        Text(
                                          'Select Bill Due Date',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: GridView.builder(
                                      padding: const EdgeInsets.all(16),
                                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 5,
                                        childAspectRatio: 1,
                                        crossAxisSpacing: 10,
                                        mainAxisSpacing: 10,
                                      ),
                                      itemCount: 31,
                                      itemBuilder: (context, index) {
                                        final day = index + 1;
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedDay = day;
                                            });
                                            Navigator.pop(context);
                                          },
                                          child: AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            decoration: BoxDecoration(
                                              color: selectedDay == day
                                                  ? Colors.deepPurple
                                                  : Colors.deepPurple.shade50,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Center(
                                              child: Text(
                                                day.toString(),
                                                style: TextStyle(
                                                  color: selectedDay == day
                                                      ? Colors.white
                                                      : Colors.deepPurple,
                                                  fontSize: 16,
                                                  fontWeight: selectedDay == day
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Bill Due Date',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.deepPurple),
                                const SizedBox(width: 12),
                                Text(
                                  '${selectedDay}${_getDaySuffix(selectedDay)} of every month',
                                  style: const TextStyle(
                                    color: Colors.deepPurple,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancel'),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.purple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text('Add'),
                                          onPressed: () async {
                              if (cardNameController.text.isNotEmpty && cardLimitController.text.isNotEmpty) {
                                final card = CreditCard(
                                  name: cardNameController.text,
                                  limit: double.parse(cardLimitController.text),
                                  dueDate: selectedDay,
                                  addedDate: DateTime.now(),
                                );
                                await Provider.of<DataProvider>(context, listen: false).addCreditCard(card);
                                if (context.mounted) {
                                  Navigator.of(context).pop();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Credit card added successfully!'),
                                      backgroundColor: Colors.deepPurple,
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                                      duration: Duration(milliseconds: 1500),
                                    ),
                                  );
                                }
                              }
                            },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFEDE7F6), Color(0xFFD1C4E9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: Selector<DataProvider, List<CreditCard>>(
              selector: (_, provider) => provider.creditCards,
              builder: (context, creditCards, _) {
                if (creditCards.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.credit_card, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No credit cards yet',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: creditCards.length,
                  padding: const EdgeInsets.only(top: 8),
                  itemBuilder: (context, index) {
                    final card = creditCards[index];
                    return Dismissible(
                      key: Key(card.name),
                      background: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 24),
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (_) async {
                        return await showDialog(
                          context: context,
                          builder: (BuildContext context) => Dialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            child: Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.deepPurple, Colors.purpleAccent],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Delete Credit Card',
                                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Are you sure you want to delete ${card.name}?',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 24),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      TextButton(
                                        onPressed: () => Navigator.of(context).pop(false),
                                        style: TextButton.styleFrom(
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                        ),
                                        child: const Text(
                                          'Cancel',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      ElevatedButton(
                                        onPressed: () => Navigator.of(context).pop(true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          elevation: 2,
                                        ),
                                        child: const Text(
                                          'Delete',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      onDismissed: (_) {
                        Provider.of<DataProvider>(context, listen: false).deleteCreditCard(index);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${card.name} deleted'),
                            backgroundColor: Colors.red,
                            behavior: SnackBarBehavior.floating,
                            margin: const EdgeInsets.only(bottom: 72, left: 16, right: 16),
                            duration: Duration(milliseconds: 1500),
                          ),
                        );
                      },
                      child: Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Card info
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          card.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Added on:',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          card.addedDate.toString().substring(0, 16),
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Limit and due date right-aligned
                                  Expanded(
                                    flex: 2,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₹${card.limit.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.deepPurple,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Due: ${card.dueDate}${_getDaySuffix(card.dueDate)}',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                        // Edit and Delete icons
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.edit),
                                              color: Colors.deepPurple,
                                              tooltip: 'Edit Card',
                                              onPressed: () => _showEditCreditCardDialog(context, card, index),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.delete_outline),
                                              color: Colors.red,
                                              tooltip: 'Delete Card',
                                              onPressed: () => _showDeleteConfirmationDialog(context, index),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Credit Card',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () => _showAddCreditCardDialog(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
