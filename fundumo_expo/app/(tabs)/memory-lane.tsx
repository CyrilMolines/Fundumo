import DateTimePicker, {
  AndroidNativeProps,
  DateTimePickerEvent,
} from '@react-native-community/datetimepicker';
import { FlashList } from '@shopify/flash-list';
import { format, formatDistanceToNow } from 'date-fns';
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
import { useMemoryLaneStore } from '@/src/state/memoryLaneStore';
import type { MemoryEntry, ResurfacedMemory } from '@/src/types';

const androidProps: AndroidNativeProps = {
  mode: 'date',
  display: 'calendar',
};

const MemoryCard = ({
  entry,
  onDelete,
}: {
  entry: MemoryEntry | ResurfacedMemory;
  onDelete: (id: string) => void;
}) => {
  const captured = format(new Date(entry.capturedOn), 'PPP');
  return (
    <ThemedView style={styles.card}>
      <View style={styles.cardHeader}>
        <View>
          <ThemedText type="subtitle">{entry.title}</ThemedText>
          <ThemedText style={styles.cardMeta}>{captured}</ThemedText>
        </View>
        <Pressable
          onPress={() =>
            Alert.alert('Delete memory?', `Remove "${entry.title}"?`, [
              { text: 'Cancel', style: 'cancel' },
              { text: 'Delete', style: 'destructive', onPress: () => onDelete(entry.id) },
            ])
          }>
          <ThemedText style={styles.deleteText}>✕</ThemedText>
        </Pressable>
      </View>
      <ThemedText style={styles.cardDescription}>{entry.description}</ThemedText>
      {entry.tags.length > 0 && (
        <View style={styles.tagRow}>
          {entry.tags.map((tag) => (
            <View key={tag} style={styles.tagPill}>
              <ThemedText style={styles.tagText}>{tag}</ThemedText>
            </View>
          ))}
        </View>
      )}
      {entry.mood && (
        <ThemedText style={styles.cardMeta}>Mood logged: {entry.mood}</ThemedText>
      )}
    </ThemedView>
  );
};

const ResurfacedStrip = ({ memories }: { memories: ResurfacedMemory[] }) => {
  if (!memories.length) {
    return (
      <ThemedText style={styles.emptyListText}>
        Nothing resurfaced today. Add more memories or widen the resurfacing window.
      </ThemedText>
    );
  }

  return (
    <View style={styles.resurfaceStrip}>
      {memories.map((memory) => (
        <View key={memory.id} style={styles.resurfaceCard}>
          <ThemedText type="defaultSemiBold">{memory.title}</ThemedText>
          <ThemedText style={styles.cardMeta}>
            {format(new Date(memory.capturedOn), 'MMM d, yyyy')}
          </ThemedText>
          <ThemedText style={styles.cardMeta}>
            {formatDistanceToNow(new Date(memory.capturedOn), { addSuffix: true })}
          </ThemedText>
        </View>
      ))}
    </View>
  );
};

export default function MemoryLaneScreen() {
  const colorScheme = useColorScheme();
  const palette = Colors[colorScheme ?? 'light'];
  const { entries, resurfaced, addMemory, deleteMemory, refreshResurfaced } =
    useMemoryLaneStore();

  const [formVisible, setFormVisible] = useState(false);
  const [title, setTitle] = useState('');
  const [description, setDescription] = useState('');
  const [tagsField, setTagsField] = useState('');
  const [mood, setMood] = useState('');
  const [capturedOn, setCapturedOn] = useState(() => new Date());
  const [showPicker, setShowPicker] = useState(false);

  const orderedEntries = useMemo(
    () =>
      [...entries].sort(
        (a, b) => new Date(b.capturedOn).getTime() - new Date(a.capturedOn).getTime(),
      ),
    [entries],
  );

  const handleAddMemory = () => {
    try {
      const tags = tagsField
        .split(',')
        .map((tag) => tag.trim())
        .filter(Boolean);
      addMemory({
        title,
        description,
        capturedOn,
        tags,
        mood,
      });
      setFormVisible(false);
      setTitle('');
      setDescription('');
      setTagsField('');
      setMood('');
      setCapturedOn(new Date());
    } catch (error) {
      Alert.alert('Unable to save memory', String(error));
    }
  };

  const handleDateChange = (event: DateTimePickerEvent, date?: Date) => {
    if (Platform.OS === 'android') {
      setShowPicker(false);
    }
    if (date) {
      setCapturedOn(date);
    }
  };

  return (
    <ThemedView style={styles.screen}>
      <Stack.Screen options={{ title: 'Memory Lane' }} />
      <FlashList
        contentContainerStyle={styles.listContent}
        data={orderedEntries}
        estimatedItemSize={220}
        keyExtractor={(item) => item.id}
        renderItem={({ item }) => <MemoryCard entry={item} onDelete={deleteMemory} />}
        ListHeaderComponent={
          <View style={styles.headerBlock}>
            <View style={styles.sectionHeader}>
              <ThemedText type="title">Daily resurfacing</ThemedText>
              <Pressable
                style={[styles.primaryButton, { backgroundColor: palette.tint }]}
                onPress={() => refreshResurfaced()}>
                <ThemedText style={styles.primaryButtonText}>Refresh</ThemedText>
              </Pressable>
            </View>
            <ResurfacedStrip memories={resurfaced} />
            <View style={styles.sectionHeader}>
              <ThemedText type="title">All memories</ThemedText>
              <Pressable
                style={[styles.primaryButton, { backgroundColor: palette.tint }]}
                onPress={() => setFormVisible(true)}>
                <ThemedText style={styles.primaryButtonText}>Add memory</ThemedText>
              </Pressable>
            </View>
          </View>
        }
        ListEmptyComponent={
          <ThemedText style={styles.emptyListText}>
            Memories you add here will resurface automatically around their anniversaries.
          </ThemedText>
        }
      />
      <Modal visible={formVisible} animationType="slide" onRequestClose={() => setFormVisible(false)}>
        <ThemedView style={styles.modalContent}>
          <View style={styles.modalHeader}>
            <ThemedText type="title">Save a memory</ThemedText>
            <Pressable onPress={() => setFormVisible(false)}>
              <ThemedText style={styles.deleteText}>Close</ThemedText>
            </Pressable>
          </View>
          <ScrollView contentContainerStyle={styles.formContent}>
            <Label text="Title" />
            <TextInput
              placeholder="e.g. First community meetup"
              value={title}
              onChangeText={setTitle}
              style={styles.input}
            />
            <Label text="Details" />
            <TextInput
              placeholder="How did it feel?"
              value={description}
              onChangeText={setDescription}
              multiline
              style={[styles.input, styles.multiline]}
            />
            <Label text="Captured on" />
            <Pressable style={styles.dateButton} onPress={() => setShowPicker(true)}>
              <ThemedText>{format(capturedOn, 'PPPP')}</ThemedText>
            </Pressable>
            {showPicker && (
              <DateTimePicker
                value={capturedOn}
                onChange={handleDateChange}
                {...(Platform.OS === 'android' ? androidProps : {})}
              />
            )}
            <Label text="Mood (optional)" />
            <TextInput placeholder="grateful, hopeful…" value={mood} onChangeText={setMood} style={styles.input} />
            <Label text="Tags" />
            <TextInput
              placeholder="family, launch, retreat"
              value={tagsField}
              onChangeText={setTagsField}
              style={styles.input}
            />
            <Pressable
              style={[styles.primaryButton, { backgroundColor: palette.tint }]}
              onPress={handleAddMemory}>
              <ThemedText style={styles.primaryButtonText}>Save</ThemedText>
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
  headerBlock: {
    gap: 16,
  },
  sectionHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: 12,
  },
  primaryButton: {
    paddingHorizontal: 16,
    paddingVertical: 10,
    borderRadius: 999,
  },
  primaryButtonText: {
    color: '#fff',
    fontWeight: '600',
  },
  resurfaceStrip: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 12,
  },
  resurfaceCard: {
    borderRadius: 16,
    padding: 16,
    flexBasis: '48%',
    backgroundColor: '#f5f7ff',
  },
  card: {
    padding: 16,
    borderRadius: 16,
    marginBottom: 12,
  },
  cardHeader: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
  },
  cardDescription: {
    marginTop: 10,
    lineHeight: 22,
  },
  cardMeta: {
    color: '#7a869a',
    marginTop: 4,
  },
  deleteText: {
    color: '#f25f5c',
  },
  tagRow: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: 6,
    marginTop: 10,
  },
  tagPill: {
    borderRadius: 999,
    paddingHorizontal: 10,
    paddingVertical: 6,
    backgroundColor: '#f2f4f7',
  },
  tagText: {
    fontSize: 12,
  },
  emptyListText: {
    textAlign: 'center',
    color: '#7a869a',
    marginVertical: 20,
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
  dateButton: {
    paddingVertical: 12,
    paddingHorizontal: 14,
    borderRadius: 12,
    borderWidth: 1,
    borderColor: '#d0d5dd',
  },
  label: {
    marginTop: 12,
    marginBottom: 4,
  },
});

