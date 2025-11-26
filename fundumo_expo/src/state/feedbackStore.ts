import AsyncStorage from '@react-native-async-storage/async-storage';
import { formatISO } from 'date-fns';
import { nanoid } from 'nanoid/non-secure';
import { create } from 'zustand';
import { createJSONStorage, persist } from 'zustand/middleware';

import type { FeedbackEntry } from '../types';

type CreateFeedbackPayload = {
  topic: string;
  message: string;
  mood?: string;
};

type FeedbackState = {
  entries: FeedbackEntry[];
  addFeedback: (payload: CreateFeedbackPayload) => FeedbackEntry;
  resolveFeedback: (id: string) => void;
  deleteFeedback: (id: string) => void;
  unresolvedCount: number;
};

const generateAnonymousCode = () => {
  const atoms = nanoid(10).toUpperCase();
  return `FUN-${atoms}`;
};

export const useFeedbackStore = create<FeedbackState>()(
  persist(
    (set, get) => ({
      entries: [],
      unresolvedCount: 0,
      addFeedback: ({ topic, message, mood }) => {
        const trimmedTopic = topic.trim();
        if (!trimmedTopic) {
          throw new Error('Feedback topic cannot be empty.');
        }
        const entry: FeedbackEntry = {
          id: nanoid(),
          topic: trimmedTopic,
          message: message.trim(),
          mood: mood?.trim(),
          createdAt: formatISO(new Date()),
          anonymousCode: generateAnonymousCode(),
        };
        const updated = [entry, ...get().entries];
        set({
          entries: updated,
          unresolvedCount: updated.filter((item) => !item.resolvedAt).length,
        });
        return entry;
      },
      resolveFeedback: (id: string) => {
        const updated = get().entries.map((entry) =>
          entry.id === id ? { ...entry, resolvedAt: formatISO(new Date()) } : entry,
        );
        set({
          entries: updated,
          unresolvedCount: updated.filter((item) => !item.resolvedAt).length,
        });
      },
      deleteFeedback: (id: string) => {
        const updated = get().entries.filter((entry) => entry.id !== id);
        set({
          entries: updated,
          unresolvedCount: updated.filter((item) => !item.resolvedAt).length,
        });
      },
    }),
    {
      name: 'feedback',
      storage: createJSONStorage(() => AsyncStorage),
      onRehydrateStorage: () => (state) => {
        if (state) {
          state.unresolvedCount = state.entries.filter((item) => !item.resolvedAt).length;
        }
      },
    },
  ),
);

