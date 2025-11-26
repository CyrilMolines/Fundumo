import AsyncStorage from '@react-native-async-storage/async-storage';

/**
 * namespaced helpers to avoid key collisions
 */
const prefix = '@fundumo:';

export const storage = {
  async get<T>(key: string, fallback: T): Promise<T> {
    try {
      const raw = await AsyncStorage.getItem(prefix + key);
      if (!raw) {
        return fallback;
      }
      return JSON.parse(raw) as T;
    } catch (error) {
      console.warn(`storage.get(${key}) failed`, error);
      return fallback;
    }
  },
  async set<T>(key: string, value: T): Promise<void> {
    try {
      await AsyncStorage.setItem(prefix + key, JSON.stringify(value));
    } catch (error) {
      console.warn(`storage.set(${key}) failed`, error);
    }
  },
  async remove(key: string): Promise<void> {
    try {
      await AsyncStorage.removeItem(prefix + key);
    } catch (error) {
      console.warn(`storage.remove(${key}) failed`, error);
    }
  },
};

