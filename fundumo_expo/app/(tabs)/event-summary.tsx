import DateTimePicker, {
  AndroidNativeProps,
  DateTimePickerEvent,
} from '@react-native-community/datetimepicker';
import { FlashList } from '@shopify/flash-list';
import { format } from 'date-fns';
import { Stack } from 'expo-router';
import React, { useMemo, useState } from 'react';
import {
  Alert,
  Modal,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  TextInput,
  View,
} from 'react-native';

import { ThemedText } from '@/components/themed-text';
import { ThemedView } from '@/components/themed-view';
import { Colors } from '@/constants/theme';
import { useColorScheme } from '@/hooks/use-color-scheme';
import { useEventSummaryStore } from '@/src/state/eventSummaryStore';
import type { EventSummary } from '@/src/types';

const androidPickerProps: AndroidNativeProps = {
  mode: 'date',
  display: 'calendar',
};

const TagCloud = ({ tags }: { tags: Record<string, number> }) => {
  const sorted = useMemo(
    () =>
      Object.entries(tags)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 6),
    [tags],
  );

  if (!sorted.length) {
    return (
      <ThemedText style={styles.emptyTagText}>
        Log your first recap to start building insights.
      </ThemedText>
    );
  }

  return (
    <View style={styles.tagGrid}>
      {sorted.map(([tag, count]) => (
        <View key={tag} style={styles.tagChip}>
          <ThemedText type="defaultSemiBold">{tag}</ThemedText>
          <ThemedText style={styles.tagCount}>×{count}</ThemedText>
        </View>
      ))}
    </View>
  );
};

const SummaryCard = ({
  summary,
  onDelete,
}: {
  summary: EventSummary;
  onDelete: (id: string) => void;
}) => {
  const eventDate = format(new Date(summary.date), 'PPP');
  return (
    <ThemedView style={styles.card}>
      <View style={styles.cardHeader}>
        <View>
          <ThemedText type="subtitle">{summary.title}</ThemedText>
          <ThemedText style={styles.cardMeta}>{eventDate}</ThemedText>
        </View>
        <Pressable
          accessibilityHint="Delete event summary"
          style={styles.deleteButton}
          onPress={() =>
            Alert.alert('Delete summary?', `Remove "${summary.title}"?`, [
              { text: 'Cancel', style: 'cancel' },
              { text: 'Delete', style: 'destructive', onPress: () => onDelete(summary.id) },
            ])
          }>
          <ThemedText style={styles.deleteText}>✕</ThemedText>
        </Pressable>
      </View>
      <ThemedText style={styles.cardDescription}>{summary.description}</ThemedText>
      <ThemedText style={styles.cardMeta}>
        {summary.mediaCount} media item{summary.mediaCount === 1 ? '' : 's'}
      </ThemedText>
      {summary.highlights.length > 0 && (
        <View style={styles.highlightList}>
          {summary.highlights.map((highlight) => (
            <View key={highlight.id} style={styles.highlightRow}>
              <ThemedText>• {highlight.text}</ThemedText>
            </View>
          ))}
        </View>
      )}
      {summary.tags.length > 0 && (
        <View style={styles.tagRow}>
          {summary.tags.map((tag) => (
            <View key={tag} style={styles.tagPill}>
              <ThemedText style={styles.tagPillText}>{tag}</ThemedText>
            </View>
          ))}
        </View>
      )}
    </ThemedView>
  );
};

export default function EventSummaryScreen() {
  const colorScheme = useColorScheme();
  const palette = Colors[colorScheme ?? 'light'];
  const [formVisible, setFormVisible] = useState(false);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [mediaCount, setMediaCount] = useState('0');
  const [eventDate, setEventDate] = useState(() => new Date());
  const [highlightsField, setHighlightsField] = useState('');
  const [tagsField, setTagsField] = useState('');
  const [showDatePicker, setShowDatePicker] = useState(false);

  const { summaries, addSummary, deleteSummary, tagCloud } = useEventSummaryStore();

  const handleAddSummary = () => {
    try {
      const highlights = highlightsField
        .split('\n')
        .map((line) => line.trim())
        .filter(Boolean);
      const tags = tagsField
        .split(',')
        .map((tag) => tag.trim())
        .filter(Boolean);
      addSummary({
        title,
        description,
        date: eventDate,
        mediaCount: Number(mediaCount) || 0,
        highlights,
        tags,
      });
      setFormVisible(false);
      setTitle('');
      setDescription('');
      setMediaCount('0');
      setHighlightsField('');
      setTagsField('');
    } catch (error) {
      Alert.alert('Unable to add summary', String(error));
    }
  };

  const handleDateChange = (event: DateTimePickerEvent, selectedDate?: Date) => {
    if (Platform.OS === 'android') {
      setShowDatePicker(false);
    }
    if (selectedDate) {
      setEventDate(selectedDate);
    }
  };

  return (
    <ThemedView style={styles.screen}>
      <Stack.Screen options={{ title: 'Event Summary Maker' }} />
      <FlashList
        contentContainerStyle={styles.listContent}
        data={summaries}
        estimatedItemSize={220}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <SummaryCard summary={item} onDelete={deleteSummary} />}
        ListHeaderComponent={
          <View style={styles.section}>
            <View style={styles.sectionHeader}>
              <ThemedText type="title">Trending tags</ThemedText>
              <Pressable
                style={[styles.primaryButton, { backgroundColor: palette.tint }]}
                onPress={() => setFormVisible(true)}>
                <ThemedText style={styles.primaryButtonText}>Add summary</ThemedText>
              </Pressable>
            </View>
            <TagCloud tags={tagCloud} />
          </View>
        }
        ListEmptyComponent={
          <ThemedText style={styles.emptyListText}>
            Capture your first milestone to unlock automated recaps.
          </ThemedText>
        }
      />
      <Modal visible={formVisible} animationType="slide" onRequestClose={() => setFormVisible(false)}>
        <ThemedView style={styles.modalContent}>
          <View style={styles.modalHeader}>
            <ThemedText type="title">New event recap</ThemedText>
            <Pressable onPress={() => setFormVisible(false)}>
              <ThemedText style={styles.deleteText}>Close</ThemedText>
            </Pressable>
          </View>
          <ScrollView contentContainerStyle={styles.formContent}>
            <Label text="Title" />
            <TextInput
              placeholder="e.g. Product launch day"
              value={title}
              onChangeText={setTitle}
              style={styles.input}
            />
            <Label text="Description" />
            <TextInput
              placeholder="Short recap..."
              value={description}
              onChangeText={setDescription}
              multiline
              style={[styles.input, styles.multiline]}
            />
            <Label text="Event date" />
            <Pressable style={styles.dateButton} onPress={() => setShowDatePicker(true)}>
              <ThemedText>{format(eventDate, 'PPPP')}</ThemedText>
            </Pressable>
            {showDatePicker && (
              <DateTimePicker
                value={eventDate}
                onChange={handleDateChange}
                {...(Platform.OS === 'android' ? androidPickerProps : {})}
              />
            )}
            <Label text="Media count" />
            <TextInput
              keyboardType="number-pad"
              value={mediaCount}
              onChangeText={setMediaCount}
              style={styles.input}
            />
            <Label text="Highlights (one per line)" />
            <TextInput
              placeholder={'Door photo booth\nInvestor toast\nTeam retrospectives'}
              value={highlightsField}
              onChangeText={setHighlightsField}
              style={[styles.input, styles.multiline]}
              multiline
            />
            <Label text="Tags (comma separated)" />
            <TextInput
              placeholder="launch, investors, product"
              value={tagsField}
              onChangeText={setTagsField}
              style={styles.input}
            />
            <Pressable
              style={[styles.primaryButton, { backgroundColor: palette.tint }]}
              onPress={handleAddSummary}>
              <ThemedText style={styles.primaryButtonText}>Save recap</ThemedText>
            </Pressable>
          </ScrollView>
        </ThemedView>
      </Modal>
    </ThemedView>
  );
}

const Label = ({ text }: { text: string }) => (
  <ThemedText type="defaultSemiBold" style={styles.label}>
    {text}
  </ThemedText>
);

const styles = StyleSheet.create({
  screen: {
    flex: 1,
  },
  listContent: {
    padding: 20,
    gap: 16,
  },
  section: {
    gap: 12,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  primaryButton: {
    backgroundColor: Colors.dark.tint,
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 999,
  },
  primaryButtonText: {
    color: '#fff',
    fontWeight: '600',
  },
  tagGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 8,
  },
  tagChip: {
    borderRadius: 10,
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#eef3ff',
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
  },
  tagCount: {
    color: '#4a6df8',
    fontWeight: '600',
  },
  emptyTagText: {
    color: '#77838c',
  },
  card: {
    padding: 16,
    borderRadius: 16,
    marginBottom: 12,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    gap: 12,
  },
  cardMeta: {
    color: '#7a869a',
    marginTop: 4,
  },
  cardDescription: {
    marginTop: 12,
    fontSize: 16,
    lineHeight: 22,
  },
  highlightList: {
    marginTop: 12,
    gap: 6,
  },
  highlightRow: {
    flexDirection: 'row',
    gap: 6,
  },
  tagRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginTop: 12,
  },
  tagPill: {
    paddingHorizontal: 10,
    paddingVertical: 6,
    borderRadius: 999,
    backgroundColor: '#f2f4f7',
  },
  tagPillText: {
    fontSize: 12,
    textTransform: 'uppercase',
    letterSpacing: 0.6,
  },
  deleteButton: {
    padding: 4,
  },
  deleteText: {
    color: '#f25f5c',
  },
  emptyListText: {
    marginTop: 40,
    textAlign: 'center',
    color: '#7a869a',
  },
  modalContent: {
    flex: 1,
    paddingHorizontal: 20,
    paddingVertical: 32,
  },
  modalHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 16,
  },
  formContent: {
    gap: 10,
    paddingBottom: 60,
  },
  input: {
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#d0d5dd',
    paddingHorizontal: 14,
    paddingVertical: 12,
    fontSize: 16,
  },
  multiline: {
    minHeight: 90,
    textAlignVertical: 'top',
  },
  label: {
    marginTop: 12,
    marginBottom: 4,
  },
  dateButton: {
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#d0d5dd',
  },
});

